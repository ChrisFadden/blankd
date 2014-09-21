import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;

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
    static Renderer renderer;
    float lrAmnt;
    float fbAmnt;
    float udAmnt;
    float scanHoriz;
    float scanVert;

    static Player[] players;
    static byte playerNum;

    int frameDelay = 1000/61;

    Window* window;

    //GameObject go1;

    bool running;

    long fpsTime;
    int fps;
    int fpsCounter;

    long frameTime;

    SDL_Joystick *joystick;

    enum Stage {
    	MAP_MAKER, GAMEPLAY
    }

    Stage stage;

    GameObject go3;

    BlockBuilder builder;

    Player player;

    static int server;

	this(Window* win, int server) {
		camera = new Camera();
		camera.setTranslation(0f,4f,1f);
		camera.moveRotation(0f,-.5f);
    	renderer = new Renderer(win, &camera);
    	this.server = server;

    	
    
    	Mix_Chunk*[1] sounds;
    	sounds = InitializeSound();

    	PlaySound(sounds[0]);
    	
    	

    	lrAmnt = 0;
    	fbAmnt = 0;
    	udAmnt = 0;
    	scanHoriz = 0;
    	scanVert = 0;

    	window = win;

    	player = new Player(0, 0, 0, &camera);
    	renderer.register(player.getGameObject());

	    builder = new BlockBuilder(-1.0, 0.0, -4.0);
	    GameObject b = builder.getGameObject();
	    b.visible = true;
	    renderer.register(b);

	    GameObject floor = new GameObject(-80,-80,160,160);
	    floor.visible = true;
	    floor.setRGB(.2f,.9f,.5f);
	    renderer.register(floor);
    	

	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;

	    SDL_JoystickEventState(SDL_ENABLE);
	    joystick = SDL_JoystickOpen(0);

	    stage = Stage.MAP_MAKER;

	    if (server == 1) {
	    	SDLNet_InitServer(1234, 20);
	    	players = new Player[20];
	    	playerNum = 0;
	    } else if (server == 0) {
	    	if (!SDLNet_InitClient("128.61.126.83", 1234)){
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
		if (stage == Stage.MAP_MAKER){
			handleMapMakerInput(&event);
			float scale = 0.6f;
			camera.position.x += lrAmnt*scale;
			camera.position.y += udAmnt*scale;
			if (camera.position.y < 1)
				camera.position.y = 1f;
			camera.position.z += fbAmnt*scale;
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
						for (int i = 0; i < playerNum; i++) {
							clearbuffer();
							writebyte(5);
							writebyte(cast(byte)players.length);
							writefloat(player.x);
							writefloat(player.y);
							writefloat(player.z);
							writefloat(player.dx);
							writefloat(player.dz);
							sendmessage(players[i].mySocket);
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
		if (server > -1){
			for (int i = 0; i < playerNum; i++) {
				players[i].x += players[i].dx;
				players[i].z += players[i].dz;
				players[i].update();
			}
			if (server == 0) {
				if (players.length > 0) {
					players[players.length-1].x += players[players.length-1].dx;
					players[players.length-1].z += players[players.length-1].dz;
					players[players.length-1].update();
				}
			}
		}

		networkCalls();

		

	}

	void networkCalls(){
		if (server == 1){
			TCPsocket client;
			if (checkSockets() > 0){
				TCPsocket tempClient = checkForNewClient();
				if (tempClient !is null) {
					writeln("New client.");
					players[playerNum] = new Player(0, 0, 0, &camera);
					renderer.register(players[playerNum].getGameObject());
					players[playerNum].mySocket = tempClient;
					playerNum++;
					clearbuffer();
					writebyte(3);
					writebyte(cast(byte)players.length);
					writebyte(playerNum);
					sendmessage(players[playerNum-1].mySocket);
				}
				for (int i = 0; i < playerNum; i++) {
					if (!readsocket(players[i].mySocket, &userDefined )){
						players[i].getGameObject().visible = false;
						players[i] = null;
						for (int j = i; j < players.length-1; j++){
							players[j] = players[j+1];
						}
						players[players.length-1] = null;
						playerNum--;
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

	static void userDefined(byte** array, TCPsocket socket){
		byte MSG_ID = readbyte(array);
		switch(MSG_ID) {
			case 1:
				writeln("Adding block.");
				float[] xyz = [readfloat(array), readfloat(array), readfloat(array),
					readfloat(array), readfloat(array), readfloat(array)];
				writeln(xyz);
				if (server == 1) {
					writeln("Sending block to other clients.");
					for (int c = 0; c < playerNum; c++){
						if (socket != players[c].mySocket){
							clearbuffer();
							writebyte(1);
							for (int i = 0; i < 6; i++)
								writefloat(xyz[i]);
							sendmessage(players[c].mySocket);
						}
					}
				}
				addBlock(xyz[0], xyz[1], xyz[2], xyz[3], xyz[4], xyz[5], 1f, .5f, .5f);
				break;
			case 2:
				writeln(readfloat(array));
				break;
			case 3:
				byte len = readbyte(array);
				byte num = readbyte(array);
				playerNum = num;
				players = new Player[len+1];
				writeln("Array length: ", players.length);
				for (int i = 0; i < num; i++){
					players[i] = new Player(0,0,0,&camera);
					renderer.register(players[i].getGameObject());
				}
				players[len] = new Player(0,0,0,&camera);
				renderer.register(players[len].getGameObject());
				break;
			case 5:
				Player p;
				byte index;
				if (server == 0){
					index = readbyte(array);
					p = players[index];
				} else if (server == 1) {
					for (int i = 0; i < playerNum; i++){
						if (players[i].mySocket == socket){
							p = players[i];
							index = cast(byte)i;
							break;
						}
					}
				}
				float newx = readfloat(array);
				float newy = readfloat(array);
				float newz = readfloat(array);
				float newdx = readfloat(array);
				float newdz = readfloat(array);
				if (p !is null) {
					p.getGameObject().visible = true;
					p.x = newx;
					p.y = newy;
					p.z = newz;
					p.dx = newdx;
					p.dz = newdz;
				}
				if (server == 1) {
					for (int i = 0; i < playerNum; i++){
						if (players[i].mySocket != socket){
							clearbuffer();
							writebyte(5);
							writebyte(index);
							writefloat(newx);
							writefloat(newy);
							writefloat(newz);
							writefloat(newdx);
							writefloat(newdz);
							sendmessage(players[i].mySocket);
						}
					}
				}
				break;
			default:
				writeln("Unsupported message.");
				break;
		}
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

	void swapMode(){
		if (stage == Stage.MAP_MAKER){
			stage = Stage.GAMEPLAY;
			player.x = camera.position.x;
			player.z = camera.position.z;
			player.y = 0;
			builder.getGameObject().visible = false;
		} else {
			stage = Stage.MAP_MAKER;
			builder.getGameObject().visible = true;
			camera.setTranslation(0f,4f,1f);
			camera.resetRotation();
			camera.moveRotation(0f,0);
		}
	}

	void moveCameraLeft(){
		camera.moveTranslation(-.1f,0f,0f);
	}
	void moveCameraRight(){
		camera.moveTranslation(.1f,0f,0f);
	}
	void moveCameraUp(){
		camera.moveTranslation(0f,0.1f,0f);
	}
	void moveCameraDown(){
		camera.moveTranslation(0f,-0.1f,0f);
	}

	void angleRight() {
		//camera.moveRotation(0f,(3.14f)/2,0f);
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
					coords[4],coords[5],.5f,1f,.5f);
				if (server == 1){
					writeln("Sending block to clients.");
					for (int c = 0; c < playerNum; c++){
						clearbuffer();
						writebyte(1);
						for (int i = 0; i < 6; i++)
							writefloat(coords[i]);
						sendmessage(players[c].mySocket);
					}
				} else if (server == 0){
					writeln("Sending block to server.");
					clearbuffer();
					writebyte(1);
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

						default:
						break;
					}
					debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_JOYBUTTONUP:
					switch(event.jbutton.button){
						case 3:
						swapMode();
						break;

						default:
						break;
					}
					debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_MOUSEBUTTONDOWN:
					switch(event.button.button){
						case SDL_BUTTON_LEFT:
							writeln("Mouse button!");
							checkCollisions();
							break;
						default:
						break;
					}
				break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							running = false;
							break;
						case SDLK_w:
							fbAmnt = -0.5;
						break;
						case SDLK_s:
							fbAmnt = 0.5;
						break;
						case SDLK_a:
							lrAmnt = -0.5;
						break;
						case SDLK_d:
							lrAmnt = 0.5;
						break;
						case SDLK_q:
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
						swapMode();
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
                        case SDLK_g:
                            swapMode();
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
        GameObject closestCol = null;
        Vector direction = camera.direction;
        Vector position = camera.position;
        uint closestIndex = 100;

        int num = 0;
        foreach (GameObject obj; renderer.objects) {
            // This should be cleaner, but you know, hackathon. Time.
            //writeln("Checking object  ", num);
            for (int i = 0; i < closestIndex; i ++) {
                float x = position.x + direction.x * i; 
                float y = position.y + direction.y * i; 
                float z = position.z + direction.z * i; 

                //writeln(obj.vBufferData.length);
                if (obj.vBufferData.length < 94) // Not a box (it's the floor at 18)
                    break;

                float x1 = obj.vBufferData[75]; // Left face x
                float x2 = obj.vBufferData[93]; // Right face x
                float y1 = obj.vBufferData[19]; // Top face y
                float y2 = obj.vBufferData[55]; // Bottom face y
                float z1 = obj.vBufferData[2]; // Front face z
                float z2 = obj.vBufferData[38]; // Back face z
                
                if (    abs(x - ((x1+x2)/2) ) < abs( (x1-x2)/2)
                        &&  abs(y - ((y1+y2)/2) ) < abs( (y1-y2)/2)
                        &&  abs(z - ((z1+z2)/2) ) < abs( (x1-z2)/2) ) {
                    writeln("A collision with object ", num);
                    if (i < closestIndex) {
                        closestIndex = i;
                        closestCol = obj;
                        writeln("Closer!");
                    }
                    break;
                }
            }
            num++;
        }

        return closestCol;

	}
}
