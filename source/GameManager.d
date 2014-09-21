import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;

import std.container;

import Window;
import Renderer;
import gameobject;
import ObjLoader;
import Player;
import Vector;

import networking;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import LoadWav;
import derelict.sdl2.mixer;

class GameManager {

	static Camera camera;
	float[] targetCamera = [0, 4, 1];
	static byte[3] teams = [0, 0, 0];
    static Renderer renderer;
    float lrAmnt;
    float fbAmnt;
    float udAmnt;
    float scanHoriz;
    float scanVert;

    static Array!(Player) players;
    static byte playerNum;

    int frameDelay = 1000/61;

    Window* window;

    int buildTime;

    //GameObject go1;

    bool running;

    long fpsTime;
    int fps;
    int fpsCounter;

    long frameTime;

    SDL_Joystick *joystick;

    enum Stage {
    	MAP_MAKER, GAMEPLAY, WAITING
    }

    static Stage stage;

    GameObject go3;

    static BlockBuilder builder;

    static Flag[3] ctfFlags;

    static Player player;
    ObjLoader objloader;
    GameObject g0;
    static int server;
    Mix_Chunk*[3] sounds;

	this(Window* win, int server, string ip_addr) {
		camera = new Camera();
		camera.setTranslation(0f,9f,11f);
		camera.moveRotation(0f,-.3f);
    	renderer = new Renderer(win, &camera);
    	this.server = server;
    	
    
    	sounds = InitializeSound();

        PlaySound(sounds[0]);
    	
    	

    	lrAmnt = 0;
    	fbAmnt = 0;
    	udAmnt = 0;
    	scanHoriz = 0;
    	scanVert = 0;

    	window = win;

    	player = new Player(0, 5, 0, &camera, 1);
    	player.playerID = 0;
    	if (server == 1)
    		teams[player.team]++;
    	renderer.register(player.getGameObject());

    	objloader = new ObjLoader();

    	for (int i = 1; i < ctfFlags.length; i++){
	    	ctfFlags[i] = new Flag(cast(byte)i);
	    	GameObject flag = ctfFlags[i].getGameObject();
	    	flag.visible = true;
	    	objloader.open("flag.obj", flag);
	    	flag.setup();
			ctfFlags[i].setColor();
	    	renderer.register(flag);
	    }



    	//players ~= player;

	    builder = new BlockBuilder(-1.0, 0.0, -4.0);
	    GameObject b = builder.getGameObject();
	    b.visible = true;
	    renderer.register(b);

	    GameObject floor = new GameObject(-150,-80,300,160);
	    floor.visible = true;
	    floor.setRGB(.2f,.9f,.5f);
	    renderer.register(floor);
    	

	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;

	    SDL_JoystickEventState(SDL_ENABLE);
	    joystick = SDL_JoystickOpen(0);

	    stage = Stage.WAITING;

	    if (server == 1) {
	    	SDLNet_InitServer(1234, 20);
	    	playerNum = 1;
	    	buildTime = 60*60;
	    } else if (server == 0) {
            if (ip_addr.length < 4)
                ip_addr = "128.61.126.83";
	    	if (!SDLNet_InitClient(ip_addr.toStringz, 1234)){
	    		return;
	    	}
	    }

	    run();
	}

	void run(){
		running = true;

		while (running) {
			step(0);
			draw();
		}

		clean();
	}

	bool checkCollision(Player player, GameObject o) {
		if (player.x+player.width > o.leftx && player.x < o.rightx) {
			if (player.z > o.backz && player.z-player.length < o.frontz) {
				if (player.y < o.topy && player.y+player.height > o.bottomy) {
					return true;
				}
			}
		}
		return false;
	}

	void jump() {
		player.y -= .1f;
		bool canJump = false;
		if (player.y <= 0f)
			canJump = true;
		if (canJump == false) {
			foreach (GameObject o ; renderer.objects) {
				if (o.solid) {
					if (checkCollision(player, o)){
						canJump = true;
						break;
					}
				}
			}
		}
		player.y += .1f;
		if (canJump)
			player.jump();
	}

	void step(float deltaTime){
		frameTime = SDL_GetTicks();

		SDL_Event event;
		if (stage == Stage.WAITING) {
			handleWaitingInput(&event);
		} else if (stage == Stage.MAP_MAKER){
			if (server == 1)
				buildTime--;
			handleMapMakerInput(&event);
			float scale = 0.6f;
			camera.position.x += lrAmnt*scale;
			camera.position.y += udAmnt*scale;
			if (camera.position.y < 1)
				camera.position.y = 1f;
			camera.position.z += fbAmnt*scale;
			if (server == 1){
				if (buildTime < 1) {
					foreach(Player p; players) {
						clearbuffer();
						writebyte(12);
						sendmessage(p.mySocket);
					}
					beginGameplay();
				}
			}
		}
		else{
			handleGameplayInput(&event);
			camera.moveTranslation(lrAmnt*player.speed, 0, -fbAmnt*player.speed);

			float movex = camera.position.x - player.x;
			player.dx = movex;
			player.x = camera.position.x;
			foreach (GameObject o ; renderer.objects) {
				if (o.solid) {
					if (checkCollision(player, o)){
						player.x -= movex;
						break;
					}
				}
			}

			float movez = camera.position.z - player.z;
			player.dz = movez;
			player.z = camera.position.z;
			foreach (GameObject o ; renderer.objects) {
				if (o.solid) {
					if (checkCollision(player, o)){
						player.z -= movez;
						break;
					}
				}
			}

			player.dy -= player.gravity;
			player.y += player.dy;
			if (player.y <= 0f){
				player.y = 0f;
				player.dy = 0;
			} else {
				foreach (GameObject o ; renderer.objects) {
					if (o.solid) {
						if (checkCollision(player, o)){
							if (player.dy > 0){
								player.y = o.bottomy - player.height;
							} else if (player.dy < 0){
								player.y = o.topy;
							}
							player.dy = 0;
						}
					}
				}
			}

			if (server > -1){
				player.sendTimer--;
				if (player.sendTimer <= 0){
					if (server == 1){
						foreach (Player p; players) {
							clearbuffer();
							writebyte(5);
							writebyte(player.playerID);
							writefloat(player.x);
							writefloat(player.y);
							writefloat(player.z);
							writefloat(player.dx);
							writefloat(player.dz);
							sendmessage(p.mySocket);
						}
					} else {
						clearbuffer();
						writebyte(5);
						writefloat(player.x);
						writefloat(player.y);
						writefloat(player.z);
						writefloat(player.dx);
						writefloat(player.dz);
						sendmessage(getSocket());
					}
					player.sendTimer = 4;
				}
			}

			camera.setTranslation(player.x,player.y+player.height,player.z);
			camera.moveRotation(-scanHoriz/20f, -scanVert/20f);
		}

		for (int i = 1; i < ctfFlags.length; i++){
				Flag flag = ctfFlags[i];
				GameObject flagObj = ctfFlags[i].getGameObject();
				if (flag.playerCarrying >= 0){
					Player carrying;
					foreach(Player p; players){
						if (p.playerID == flag.playerCarrying){
							carrying = p;
							break;
						}
					}
					if (player.playerID == flag.playerCarrying)
						carrying = player;
					if (carrying !is null){
						flag.getGameObject().x = carrying.x;
						flag.getGameObject().y = carrying.y+carrying.height;
						flag.getGameObject().z = carrying.z;
						flag.getGameObject().updateMatrix();
					}
				}
				if (stage == Stage.GAMEPLAY && abs(flagObj.x-player.x) < 1){
					if (abs(flagObj.y-player.y) < 5){
						if (abs(flagObj.z-player.z) < 1){

							if (flag.team == player.team){
								if (!flag.isHome() && flag.playerCarrying < 0){
									if (server == 1) {
										flag.reset();
										foreach(Player p; players){
											clearbuffer();
											writebyte(8);
											writebyte(cast(byte)i);
											sendmessage(p.mySocket);
										}
									} else if (server == 0) {
										clearbuffer();
										writebyte(8);
										writebyte(cast(byte)i);
										sendmessage(getSocket());
									}
								} else {
									byte otherFlagInd = i == 1 ? 2 : 1;
									Flag otherFlag = ctfFlags[otherFlagInd];
									if (otherFlag.playerCarrying == player.playerID){
										otherFlag.reset();
										if (server == 1){
											writeln("Score from team ", otherFlagInd == 2 ? "red": "blue");
											foreach(Player p ; players){
												clearbuffer();
												writebyte(11);
												writebyte(otherFlagInd);
												sendmessage(p.mySocket);
											}
										} else if (server == 0){
											clearbuffer();
											writebyte(11);
											writebyte(otherFlagInd);
											sendmessage(getSocket());
										}
									}
								}
							}

							else {
								if (flag.playerCarrying < 0){
									writeln("Pickup!");
									if (server == 1) {
										flag.playerCarrying = player.playerID;
										foreach(Player p; players){
											clearbuffer();
											writebyte(9);
											writebyte(cast(byte)i);
											writebyte(player.playerID);
											sendmessage(p.mySocket);
										}
									} else if (server == 0) {
										clearbuffer();
										writebyte(9);
										writebyte(cast(byte)i);
										writebyte(player.playerID);
										sendmessage(getSocket());
									}
								}
							}
						}
					}
				}
			}

		if (server > -1){
			foreach (Player p; players){
				p.x += p.dx;
				p.z += p.dz;
				p.update();
			}
		}

		networkCalls();
	}

	float abs(float k){
		if (k < 0f)
			return -k;
		return k;
	}

	void networkCalls(){
		if (server == 1){
			TCPsocket client;
			if (checkSockets() > 0){
				TCPsocket tempClient = checkForNewClient();
				if (tempClient !is null) {
					writeln("New client.");
					byte pTeam = teams[1] > teams[2] ? 2 : 1;
					Player tempPlayer = new Player(0, 0, 0, &camera,pTeam);
					tempPlayer.playerID = playerNum;
					teams[tempPlayer.team]++;
					renderer.register(tempPlayer.getGameObject());
					tempPlayer.mySocket = tempClient;
					playerNum++;
					clearbuffer();
					writebyte(2);
					writebyte(tempPlayer.team);
					writebyte(tempPlayer.playerID);
					sendmessage(tempPlayer.mySocket);

					foreach(Player p ; players){
						clearbuffer();
						writebyte(3);
						writebyte(p.playerID);
						writebyte(p.team);
						sendmessage(tempPlayer.mySocket);

						clearbuffer();
						writebyte(3);
						writebyte(tempPlayer.playerID);
						writebyte(tempPlayer.team);
						sendmessage(p.mySocket);
					}
					clearbuffer();
					writebyte(3);
					writebyte(player.playerID);
					writebyte(player.team);
					sendmessage(tempPlayer.mySocket);

					players ~= tempPlayer;
				}
				foreach (Player p; players) {
					if (!readsocket(p.mySocket, &userDefined )){
						p.getGameObject().visible = false;
						p.active = false;
						p = null;
					}
				}
			}
		} else if (server == 0){
			if (checkSockets() > 0){
				if (!readsocket(getSocket(), &userDefined))
					running = false;
			}
		}
	}

	static int userDefined(byte** array, TCPsocket socket){
		byte MSG_ID = readbyte(array);
		switch(MSG_ID) {
			case 1:
				writeln("\n\nAdding block.\n\n");
				byte pId = readbyte(array);
				float[] xyz = [readfloat(array), readfloat(array), readfloat(array),
					readfloat(array), readfloat(array), readfloat(array)];
				writeln(xyz);
				if (server == 1) {
					writeln("Sending block to other clients.");
					foreach(Player p; players){
						if (socket != p.mySocket){
							clearbuffer();
							writebyte(1);
							writebyte(pId);
							for (int i = 0; i < 6; i++)
								writefloat(xyz[i]);
							sendmessage(p.mySocket);
						}
					}
				}
				Player pTemp;
				foreach(Player p ; players){
					if (p.playerID == pId){
						pTemp = p;
						break;
					}
				}
				float[] rgb = [.5f, 1f, .5f];
				if (pTemp !is null){
					rgb[0] = pTemp.getGameObject().r;
					rgb[1] = pTemp.getGameObject().g;
					rgb[2] = pTemp.getGameObject().b;
				}
				addBlock(xyz[0], xyz[1], xyz[2], xyz[3], xyz[4], xyz[5], rgb[0], rgb[1], rgb[2]);
				return 6*4+1+1;
			case 2:
				byte pTeam = readbyte(array);
				byte myID = readbyte(array);
				player.playerID = myID;
				writeln("You are player ", myID);
				player.setTeam(pTeam);
				return 1+2;
			case 3:
				byte pId = readbyte(array);
				byte pTeam = readbyte(array);
				writeln("New player: ", pId);
				Player temp = new Player(0,0,0,&camera,pTeam);
				temp.playerID = pId;
				renderer.register(temp.getGameObject());
				players ~= temp;
				return 1+2;
			case 6:
				if (server == 1){
					byte pId = readbyte(array);
					if (pId == player.playerID)
						getShot();
					else {
						foreach (Player p; players){
							if (p.playerID == pId){
								clearbuffer();
								writebyte(6);
								sendmessage(p.mySocket);
								break;
							}
						}
					}
					return 1+1;
				} else {
					getShot();
					return 1;
				}
			case 5:
				Player plyr;
				byte pId;
				if (server == 0){
					pId = readbyte(array);
					foreach (Player p; players){
						if (p.playerID == pId){
							plyr = p;
							break;
						}
					}
				} else if (server == 1) {
					foreach (Player p; players){
						if (p.mySocket == socket){
							plyr = p;
							break;
						}
					}
				}
				float newx = readfloat(array);
				float newy = readfloat(array);
				float newz = readfloat(array);
				float newdx = readfloat(array);
				float newdz = readfloat(array);
				if (plyr !is null) {
					plyr.getGameObject().visible = true;
					plyr.x = newx;
					plyr.y = newy;
					plyr.z = newz;
					plyr.dx = newdx;
					plyr.dz = newdz;
				}
				if (server == 1) {
					foreach (Player p; players){
						if (p.mySocket != socket){
							clearbuffer();
							writebyte(5);
							writebyte(plyr.playerID);
							writefloat(newx);
							writefloat(newy);
							writefloat(newz);
							writefloat(newdx);
							writefloat(newdz);
							sendmessage(p.mySocket);
						}
					}
				}
				return 1+(server == 0 ? 1 : 0)+(4*5);
			case 7:
				beginBuildPhase();
				return 1;
			case 8: // Reset flag to home
				byte flagNum = readbyte(array);
				
				if (ctfFlags[flagNum].playerCarrying < 0){
					ctfFlags[flagNum].reset();
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(8);
							writebyte(flagNum);
							sendmessage(p.mySocket);
						}
					}
				}
				return 1+2;
			case 9: // Pickup flag
				byte flagNum = readbyte(array);
				byte pId = readbyte(array);

				if (ctfFlags[flagNum].playerCarrying < 0){
					writeln("Pickup flag!");
					ctfFlags[flagNum].playerCarrying = pId;
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(9);
							writebyte(flagNum);
							writebyte(pId);
							sendmessage(p.mySocket);
						}
					}
				}
				return 3;
			case 10: // Drop flag
				byte flagNum = readbyte(array);

				if (ctfFlags[flagNum].playerCarrying >= 0){
					ctfFlags[flagNum].playerCarrying = -1;
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(10);
							writebyte(flagNum);
							sendmessage(p.mySocket);
						}
					}
				}
				return 2;
			case 11: // Score
				byte flagNum = readbyte(array);
				writeln("Score from team ", flagNum == 2 ? "red": "blue");
				ctfFlags[flagNum].reset();
				if (server == 1){
					foreach (Player p ; players){
						clearbuffer();
						writebyte(11);
						writebyte(flagNum);
						sendmessage(p.mySocket);
					}
				}
				return 2;
			case 12:
				beginGameplay();
				return 1;
			default:
				writeln("Unsupported message.");
				return 1;
		}
	}

	static void beginBuildPhase(){
		writeln("Begin build phase!");
		builder.startx = player.team == 1 ? -25*BlockBuilder.dx : 24*BlockBuilder.dx;
		builder.startz = 0;
		for(int i = 1; i < ctfFlags.length; i++){
			GameObject flag = ctfFlags[i].getGameObject();
			flag.x = ctfFlags[i].team == 1 ? -25*BlockBuilder.dx : 24*BlockBuilder.dx;
			flag.z = 0;
			flag.y = BlockBuilder.dy*2;
			flag.updateMatrix();
			addBlock(flag.x-BlockBuilder.dx,
					flag.y-BlockBuilder.dy*2,
					flag.z+BlockBuilder.dz,
					flag.x+BlockBuilder.dx*2,
					flag.y-BlockBuilder.dy,
					flag.z-BlockBuilder.dz*2,
					flag.r,
					0,
					flag.b);
			ctfFlags[i].lock();
		}
		builder.startx -= player.team == 1 ? 2*BlockBuilder.dx : -2*BlockBuilder.dx;
		builder.team = player.team;
		builder.updateMesh();
		camera.position.x = builder.startx;
		stage = Stage.MAP_MAKER;
	}

	void draw(){
		renderer.draw();


		fpsCounter++;
		if (SDL_GetTicks() - fpsTime >= 1000){
			fps = fpsCounter;
			fpsCounter = 0;
			fpsTime = SDL_GetTicks();
			//debug writeln("FPS: ", fps);
		}

		int time = cast(int)(SDL_GetTicks() - frameTime);
		if (frameDelay <= time)
			time = 0;

		(*window).pause(frameDelay - time);
	}

	void clean(){

	}

	static void beginGameplay(){
		stage = Stage.GAMEPLAY;
		Flag myFlag = ctfFlags[player.team];
		player.x = myFlag.lockx;
		player.z = myFlag.lockz;
		player.y = myFlag.locky;
		player.startx = player.x;
		player.starty = player.y;
		player.startz = player.z;
		camera.setTranslation(player.x,player.y+player.height,player.z);
		player.update();
		builder.getGameObject().visible = false;
	}

	void swapMode(){
		if (stage == Stage.MAP_MAKER){
			beginGameplay();
		} else {
			stage = Stage.MAP_MAKER;
			builder.getGameObject().visible = true;
			camera.setTranslation(0f,9f,11f);
			camera.resetRotation();
			camera.moveRotation(0f,-0.3f);
		}
	}

	void moveCameraLeft(){
		camera.moveTranslation(-1f,0f,0f);
	}
	void moveCameraRight(){
		camera.moveTranslation(1f,0f,0f);
	}
	void moveCameraUp(){
		camera.moveTranslation(0f,1f,0f);
	}
	void moveCameraDown(){
		camera.moveTranslation(0f,-1f,0f);
	}

	static void getShot() {
		player.hp--;
		if (player.hp<1){
			player.spawn();
			camera.setTranslation(player.x,player.y+player.height,player.z);
			byte otherFlagInd = player.team == 1 ? 2 : 1;
			Flag otherFlag = ctfFlags[otherFlagInd];
			if (otherFlag.playerCarrying == player.playerID){
				otherFlag.playerCarrying = -1;
				if (server == 1){
					foreach(Player p; players){
						clearbuffer();
						writebyte(10);
						writebyte(otherFlagInd);
						sendmessage(p.mySocket);
					}
				} else if (server == 0){
					clearbuffer();
					writebyte(10);
					writebyte(otherFlagInd);
					sendmessage(getSocket());
				}
			}
		}
	}

	void angleRight() {
		//camera.moveRotation(0f,(3.14f)/2,0f);
	}

	void shoot(){
		GameObject shot = checkCollisions();
		foreach (Player p; players){
			if (p.getGameObject() == shot){
				writeln("You shot player ", p.playerID, "!");
				if (server == 1){
					clearbuffer();
					writebyte(6);
					sendmessage(p.mySocket);
				} else if (server == 0) {
					clearbuffer();
					writebyte(6);
					writebyte(p.playerID);
					sendmessage(getSocket());
				}
				break;
			}
		}
	}

	void quitBlock() {
		builder.quit();
	}
	void moveBlockLeft(){
		builder.left();
		//camera.moveTranslation(-.05f,0f,0f);
	}
	void moveBlockRight(){
		builder.right();
		//camera.moveTranslation(.05f,0f,0f);
	}
	void moveBlockUp(){
		builder.up();
		//camera.moveTranslation(0f,0.05f,0f);
	}
	void moveBlockDown(){
		builder.down();
		//camera.moveTranslation(0f,-0.05f,0f);
	}
	void raiseBlock(){
		builder.raise();
	}
	void lowerBlock(){
		builder.lower();
	}
	void placeBlock(){
		if (builder.placing){
			float[] coords = builder.place();
			if (coords !is null) {
				addBlock(coords[0],coords[1],coords[2],coords[3],
					coords[4],coords[5],
					player.getGameObject().r,
					player.getGameObject().g,
					player.getGameObject().b);
				if (server == 1){
					writeln("Sending block to clients.");
					foreach(Player p; players){
						clearbuffer();
						writebyte(1);
						writebyte(player.playerID);
						for (int i = 0; i < 6; i++)
							writefloat(coords[i]);
						sendmessage(p.mySocket);
					}
				} else if (server == 0){
					writeln("Sending block to server.");
					clearbuffer();
					writebyte(1);
					writebyte(player.playerID);
					for (int i = 0; i < 6; i++)
						writefloat(coords[i]);
					sendmessage(getSocket());
				}
			}
		}
		else
			builder.beginPlace();
	}

	static void addBlock(float x1, float y1, float z1, float x2, float y2, float z2, float r, float g, float b){
		GameObject got = new GameObject(x1,y1,z1,x2,y2,z2);
        got.visible = true;
        got.solid = true;
        got.setRGB(r, g, b);
        got.updateMatrix();
        renderer.register(got);
	}

	void handleGameplayInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYAXISMOTION:
				if ((event.jaxis.value < -3200) || (event.jaxis.value > 3200)){
					if (event.jaxis.axis == 0) {
						lrAmnt = event.jaxis.value/(cast(float)short.max);
					} if (event.jaxis.axis == 1) {
						fbAmnt = event.jaxis.value/(cast(float)short.max);
					} else if (event.jaxis.axis == 2) {
						scanHoriz = event.jaxis.value/(cast(float)short.max);
					} else if (event.jaxis.axis == 5) {
						scanVert = event.jaxis.value/(cast(float)short.max);
					}
				} else {
					if (event.jaxis.axis == 0){
						lrAmnt = 0;
					} else if (event.jaxis.axis == 1) {
						fbAmnt = 0;
					} else if (event.jaxis.axis == 2) {
						scanHoriz = 0;
					} else if (event.jaxis.axis == 5) {
						scanVert = 0;
					}
				}
				break;
				case SDL_JOYBUTTONDOWN:
					switch(event.jbutton.button){
						case 1:
						jump();
						break;
						case 7:
						shoot();
						break;
						default:
						break;
					}
					//debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_JOYBUTTONUP:
					switch(event.jbutton.button){
						case 3:
						//swapMode();
						break;

						default:
						break;
					}
					//debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_MOUSEBUTTONDOWN:
					switch(event.button.button){
						case SDL_BUTTON_LEFT:
							shoot();
							break;
						default:
						break;
					}
				break;
                case SDL_MOUSEMOTION:
                    int midx = window.width()/2;
                    int midy = window.height()/2;
                    int x = event.motion.x;
                    int y = event.motion.y;
                    int difx = midx-x;
                    int dify = midy-y;
                    camera.moveRotation(difx/400f, dify/400f);
                    SDL_WarpMouseInWindow(window.window, midx, midy);
                    break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							running = false;
							break;
						case SDLK_w:
							fbAmnt = -1;
						break;
						case SDLK_s:
							fbAmnt = 1;
						break;
						case SDLK_a:
							lrAmnt = -1;
						break;
						case SDLK_d:
							lrAmnt = 1;
						break;
						case SDLK_q:
							scanHoriz = -0.5;
							break;
						case SDLK_e: 
							scanHoriz = 0.5;
						break;
						case SDLK_SPACE:
							jump();
						break;
						default:
						break;
					}
					break;

				case SDL_KEYUP:
					switch(event.key.keysym.sym){
						case SDLK_w:
							fbAmnt = 0;
						break;
						case SDLK_s:
							fbAmnt = 0;
						break;
						case SDLK_a:
							lrAmnt = 0;
						break;
						case SDLK_d:
							lrAmnt = 0;
						break;
						case SDLK_q:
							scanHoriz = 0;
							break;
						case SDLK_e: 
							scanHoriz = 0;
							break;
						case SDLK_g:
							//swapMode();
						break;
						default:
						break;
					}
					break;
				default:
				break;
			}
		}
	}

	void handleWaitingInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							running = false;
							break;
						case SDLK_RETURN:
							if (server != 0){
								foreach (Player p ; players){
									clearbuffer();
									writebyte(7);
									sendmessage(p.mySocket);
								}
								beginBuildPhase();
							}
							break;
						default:
							break;
					}
					break;
				default:
					break;
			}
		}
	}

	void handleMapMakerInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYBUTTONDOWN:
					switch(event.jbutton.button){
						case 1:
						placeBlock();
							break;
						case 2:
						quitBlock();
							break;
						case 5:
						raiseBlock();
							break;
						case 4:
						lowerBlock();
							break;
						case 6:
						udAmnt = -.25f;
							break;
						case 7:
						udAmnt = .25f;
							break;
						default:
						break;
					}
					debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_JOYBUTTONUP:
					switch(event.jbutton.button){
						case 6:
						udAmnt = 0f;
							break;
						case 7:
						udAmnt = 0f;
							break;
						case 3:
						//swapMode();
							break;
						default:
						break;
					}
				break;
				case SDL_JOYHATMOTION:
					if (event.jhat.value & SDL_HAT_UP) {
						moveBlockUp();
					} else if (event.jhat.value & SDL_HAT_RIGHT) {
						moveBlockRight();
					} else if (event.jhat.value & SDL_HAT_DOWN) {
						moveBlockDown();
					} else if (event.jhat.value & SDL_HAT_LEFT) {
						moveBlockLeft();
					}
				break;
				case SDL_JOYAXISMOTION:
				if ((event.jaxis.value < -3200) || (event.jaxis.value > 3200)){
					if (event.jaxis.axis == 0) {
						lrAmnt = event.jaxis.value/(cast(float)short.max);
					} else if (event.jaxis.axis == 1) {
						fbAmnt = event.jaxis.value/(cast(float)short.max);
					}
				} else {
					if (event.jaxis.axis == 0){
						lrAmnt = 0;
					} else if (event.jaxis.axis == 1) {
						fbAmnt = 0;
					} 
				}
				break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							running = false;
							break;
						case SDLK_a:
							moveBlockLeft();
							break;
						case SDLK_d:
							moveBlockRight();
							break;
						case SDLK_w:
							moveBlockUp();
							break;
						case SDLK_s:
							moveBlockDown();
							break;
						case SDLK_RETURN:
							placeBlock();
							break;
						case SDLK_UP:
							raiseBlock();
							break;
						case SDLK_DOWN:
							lowerBlock();
							break;
						case SDLK_e:
							angleRight();
							break;
						case SDLK_r:
							quitBlock();
							break;
						case SDLK_i:
							moveCameraUp();
							//fbAmnt = -1f;
							break;
						case SDLK_j:
							//lrAmnt = 1f;
							moveCameraLeft();
							break;
						case SDLK_k:
							//fbAmnt = 1f;
							moveCameraDown();
							break;
						case SDLK_l:
							//lrAmnt = -1f;
							moveCameraRight();
							break;
						default:
						break;
					}
				break;
				case SDL_KEYUP:
					switch(event.key.keysym.sym){
						case SDLK_g:
                            //swapMode();
                        break;
                        default:
                        break;
					}
				break;
				default:
				break;
			}
		}
	}

    GameObject checkCollisions()
    {
        PlaySound(sounds[1]);

        GameObject closestCol = null;
        Vector direction = camera.direction;
        Vector position = camera.position;
        int closestIndex = -100;

        int num = 0;
        foreach (GameObject obj; renderer.objects) {
            // This should be cleaner, but you know, hackathon. Time.
            //writeln("Checking object  ", num);
            for (float i = 0; i > -100; i-=.1) {
                float x = position.x + direction.x * i; 
                float y = position.y + direction.y * -i; 
                float z = position.z + direction.z * i; 

                //writeln(obj.vBufferData.length);
                if (obj.vBufferData.length < 94) // Not a box (it's the floor at 18)
                    break;

                float x1 = obj.vBufferData[75]+obj.x; // Left face x
                float x2 = obj.vBufferData[93]+obj.x; // Right face x
                float y1 = obj.vBufferData[19]+obj.y; // Top face y
                float y2 = obj.vBufferData[55]+obj.y; // Bottom face y
                float z1 = obj.vBufferData[2]+obj.z; // Front face z
                float z2 = obj.vBufferData[38]+obj.z; // Back face z
                
                if (    abs(x - ((x1+x2)/2) ) < abs( (x1-x2)/2)
                        &&  abs(y - ((y1+y2)/2) ) < abs( (y1-y2)/2)
                        &&  abs(z - ((z1+z2)/2) ) < abs( (z1-z2)/2) ) {
                    writeln("A collision with object ", num);
                    if (i > closestIndex) {
                        closestIndex = to!int(i);
                        closestCol = obj;
                    }
                    break;
                }
            }
            num++;
        }
        float x = position.x + direction.x * closestIndex; 
        float y = position.y + direction.y * -closestIndex; 
        float z = position.z + direction.z * closestIndex; 
        position.toString();
        direction.toString();
        GameObject hitObj = new GameObject(x-.1,y-.1,z-.1,x+.1,y+.1,z+.1);
        hitObj.visible = true;
        renderer.register(hitObj);
        return closestCol;
	}
}

class BlockBuilder {
    float startx, starty, startz;
    static float dx = 2.0;
    static float dy = 1.0;
    static float dz = 2.0;
    float width;
    float length;
    float height;

    bool placing;

    byte team;

    GameObject gameObject;

    this(float startx, float starty, float startz) {
        gameObject = new GameObject(startx,starty,startz,startx+dx,starty+dy,startz-dz);
        gameObject.setRGB(.7,.7,.6);
        gameObject.updateMatrix();
        this.startx = startx;
        this.starty = starty;
        this.startz = startz;
        width = dx;
        length = dz;
        height = dy;
        placing = false;
        team = 0;
    }

    void beginPlace() {
        placing = true;
        gameObject.setRGB(1,1,0.9);
    }

    float[6] place() {
        float[6] output = [startx, starty, startz, startx+width, starty+height, startz-length];
        placing = false;
        startx = startx+width;
        reset();
        return output;
    }

    GameObject getGameObject() {
        return gameObject;
    }

    void reset() {
        gameObject.setRGB(.7,.7,0.6);
        width = dx;
        length = dz;
        height = dy;
        gameObject.updateMatrix();
        updateMesh();
    }

    void quit() {
        placing = false;
        reset();
    }

    void right() {
        if (placing){
        	if (team != 1 || startx+width < 0)
            	width += dx;
        }
        else{
        	if (team != 1 || startx+dx < 0)
            	startx += dx;
        }
        updateMesh();
    }

    void left() {
        if (placing){
            if (width > dx)
                width -= dx;
            else if (team != 2 || startx > 0)
                startx -= dx;
        } else if (team != 2 || startx > 0){
            startx -= dx;
        }
        updateMesh();
    }

    void up() {
        if (placing)
            length += dz;
        else
            startz -= dz;
        updateMesh();
    }

    void down() {
        if (placing) {
            if (length > dz)
                length -= dz;
            else
                startz += dz;
        } else {
            startz += dz;
        }
        updateMesh();
    }

    void raise() {
        if (placing)
            height += dy;
        else
            starty += dy;
        updateMesh();
    }

    void lower() {
        if (placing) {
            if (height > dy)
                height -= dy;
        } else if (starty > 0f){
            starty -= dy;
        }
        updateMesh();
    }

    void updateMesh() {
        gameObject.setVertexBuffer(startx,starty,startz,startx+width,starty+height,startz-length);
        gameObject.updateMesh();
    }
}

