import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;

import std.container;

import Window;
import Renderer;
import Menu;
import gameobject;
import BlockBuilder;
import ObjLoader;
import Player;
import Vector;
import ResourceManager;
import KeyManager;

import networking;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import LoadWav;
import derelict.sdl2.mixer;

class GameManager {

	static const int MSG_NEWBLOCK = 1;
	static const int MSG_MYINFO = 2;
	static const int MSG_NEWPLAYER = 3;
	static const int MSG_DEATH = 4;
	static const int MSG_UPDATEXYZ = 5;
	static const int MSG_SHOT = 6;
	static const int MSG_BEGINBUILD = 7;
	static const int MSG_FLAGRESET = 8;
	static const int MSG_FLAGPICKUP = 9;
	static const int MSG_FLAGDROP = 10;
	static const int MSG_FLAGSCORE = 11;
	static const int MSG_BEGINGAMEPLAY = 12;
	static const int MSG_RESPAWN = 13;
	static const int MSG_UPDATEMOVEMENT = 14;
	static const int MSG_UPDATECAMERA = 15;
	static const int MSG_JUMP = 16;
	static const int MSG_CLOSED = 17;

	static Camera camera;
	float[] targetCamera = [0, 4, 1];
	static byte[3] teams = [0, 0, 0];
	static int[3] score = [0, 0, 0];
    static Renderer renderer;
    static ResourceManager resman;
    float lrAmnt;
    float fbAmnt;
    float udAmnt;
    float scanHoriz;
    float scanVert;

    static Array!(Player) players;
    static byte playerNum;

    int frameDelay = 1000/61;

    Window window;

    int buildTime;

    //GameObject go1;

    static bool running;

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
    static Settings settings;
    static Mix_Chunk*[4] sounds;
    static KeyManager keyman;

	this(Window win, Renderer renderer, Settings settings) {
		camera = new Camera();
		camera.setTranslation(0f,9f,11f);
		camera.moveRotation(0f,-.3f);
    	this.renderer = renderer;
        renderer.setCamera(camera);
    	resman = ResourceManager.getResourceManager();
        this.settings = settings;
    	this.server = settings.server;
    	keyman = new KeyManager(this);

    	char[] musicName1 = cast(char[])"bullet.wav";
    	char[] musicName2 = cast(char[])"Teleport.wav";
    	char[] musicName3 = cast(char[])"Power_Up.wav";
		char[] musicName4 = cast(char[])"hitByBullet.wav";

		resman.loadSound(musicName2);
		resman.loadSound(musicName1);
		resman.loadSound(musicName3);
		resman.loadSound(musicName4);
		sounds = resman.getSound();
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
			ctfFlags[i].setColor();
	    	renderer.register(flag);
	    }



    	//players ~= player;

	    builder = new BlockBuilder(-1.0, 0.0, -4.0);
	    GameObject b = builder.getGameObject();
	    b.visible = true;
	    renderer.register(b);

	    GameObject floor = new GameObject(-150,80,300,-160);
	    floor.visible = true;
	    floor.setColor(.2f,.9f,.5f);
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
	    	/*
	    	writeln("Please enter the build time, in minutes.");
	    	char[] buf;
    		stdin.readln(buf);
    		string s = buf;
    		*/
	    	buildTime = settings.build_time * 60;
	    } else if (server == 0) {
            if (settings.ip_addr.length < 4)
                settings.ip_addr = "127.0.0.1";
            writeln("Connecting to ", settings.ip_addr);
	    	if (!SDLNet_InitClient(settings.ip_addr.toStringz, 1234)){
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
		if (player.x+player.width/2 > o.leftx && player.x-player.width/2 < o.rightx) {
			if (player.z+player.length/2 > o.backz && player.z-player.length/2 < o.frontz) {
				if (player.y < o.topy && player.y+player.height > o.bottomy) {
					return true;
				}
			}
		}
		return false;
	}

	void jump() {
		bool canJump = false;
		if (player.y <= 0f)
			canJump = true;
		if (canJump == false) {
			canJump = !placeFree(player, 0, -.1f, 0);
		}
		if (canJump){
			if (server > -1){
				clearbuffer();
				writebyte(MSG_JUMP);
				writebyte(player.playerID);
				if (server == 1){
					foreach (Player p; players) {
						sendmessage(p.mySocket, false);
					}
					clearbuffer();
				} else {
					sendmessage(getSocket());
				}
			}
			player.jump();
		}
	}

	bool placeFree(Player player, float dx, float dy, float dz){
		player.x += dx;
		player.y += dy;
		player.z += dz;
		bool output = true;
		foreach (GameObject o ; renderer.objects) {
			if (o.solid) {
				if (checkCollision(player, o)){
					output = false;
					break;
				}
			}
		}
		player.x -= dx;
		player.y -= dy;
		player.z -= dz;
		return output;
	}

	void step(float deltaTime){
		frameTime = SDL_GetTicks();

		networkCalls();

		SDL_Event event;
		if (stage == Stage.WAITING) {
			keyman.handleWaitingInput(&event);
		} else if (stage == Stage.MAP_MAKER){
			if (server == 1)
				buildTime--;
			keyman.handleMapMakerInput(&event);
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
						writebyte(MSG_BEGINGAMEPLAY);
						sendmessage(p.mySocket);
					}
					beginGameplay();
				}
			}
		}
		else{
			keyman.handleGameplayInput(&event);

			player.lrAmnt = lrAmnt;
			player.fbAmnt = fbAmnt;
			player.scanx = -scanHoriz/20f;
			player.scanz = -scanVert/20f;
			camera.moveRotation(player.scanx, player.scanz);

			if (player.isAlive)
				movePlayer(player);
			player.update();
			foreach (Player plyr ; players){
				if (plyr.isAlive)
					movePlayer(plyr);
				plyr.update();
			}

			if (!player.isAlive){
				player.respawnTimer--;
				if (player.respawnTimer <= 0){
					renderer.isDead = false;
					clearbuffer();
					writebyte(MSG_RESPAWN);
					writebyte(player.playerID);
					if (server == 0){
						sendmessage(getSocket());
					} else if (server == 1){
						foreach(Player p; players){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
					player.spawn();
					player.getGameObject().visible = false;
				}
			}

			if (server > -1 && player.isAlive){
				player.sendTimer--;

				if (player.sendTimer <= 0){
					clearbuffer();
					writebyte(MSG_UPDATEXYZ);
					writebyte(player.playerID);
					writefloat(player.x);
					writefloat(player.y);
					writefloat(player.z);
					player.setOld();
					if (server == 1){
						foreach (Player p; players) {
							sendmessage(p.mySocket, false);
						}
						clearbuffer();
					} else {
						sendmessage(getSocket());
					}
					player.sendTimer = 15;
				}

				if (player.oldlrAmnt != player.lrAmnt ||
					player.oldfbAmnt != player.fbAmnt) {
					clearbuffer();
					writebyte(MSG_UPDATEMOVEMENT);
					writebyte(player.playerID);
					writefloat(player.lrAmnt);
					writefloat(player.fbAmnt);
					if (server == 1){
						foreach (Player p; players) {
							sendmessage(p.mySocket, false);
						}
						clearbuffer();
					} else {
						sendmessage(getSocket());
					}
					player.oldlrAmnt = player.lrAmnt;
					player.oldfbAmnt = player.fbAmnt;
				}

				if (camera.oldHorizontalAngle != camera.horizontalAngle ||
					camera.oldVerticalAngle != camera.verticalAngle) {
					clearbuffer();
					writebyte(MSG_UPDATECAMERA);
					writebyte(player.playerID);
					writefloat(camera.horizontalAngle);
					writefloat(camera.verticalAngle);
					if (server == 1){
						foreach (Player p; players) {
							sendmessage(p.mySocket, false);
						}
						clearbuffer();
					} else {
						sendmessage(getSocket());
					}
					camera.oldHorizontalAngle = camera.horizontalAngle;
					camera.oldVerticalAngle = camera.verticalAngle;
				}
			}
		}

		// FLAGS //
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
				if (player.isAlive && stage == Stage.GAMEPLAY && abs(flagObj.x-player.x) < 2){
					if (abs(flagObj.z-player.z) < 2){
						if (abs(flagObj.y-player.y) < 7){

							if (flag.team == player.team){
								if (!flag.isHome() && flag.playerCarrying < 0){
									if (server == 1) {
										flag.reset();
										foreach(Player p; players){
											clearbuffer();
											writebyte(MSG_FLAGRESET);
											writebyte(cast(byte)i);
											sendmessage(p.mySocket);
										}
									} else if (server == 0) {
										clearbuffer();
										writebyte(MSG_FLAGRESET);
										writebyte(cast(byte)i);
										sendmessage(getSocket());
									}
								} else if (flag.isHome()){
									byte otherFlagInd = i == 1 ? 2 : 1;
									Flag otherFlag = ctfFlags[otherFlagInd];
									if (otherFlag.playerCarrying == player.playerID){
										otherFlag.reset();
										if (server == 1){
											byte teamScore = player.team;
											scoreForTeam(teamScore);
											foreach(Player p ; players){
												clearbuffer();
												writebyte(MSG_FLAGSCORE);
												writebyte(otherFlagInd);
												sendmessage(p.mySocket);
											}
										} else if (server == 0){
											clearbuffer();
											writebyte(MSG_FLAGSCORE);
											writebyte(otherFlagInd);
											sendmessage(getSocket());
										}
									}
								}
							}

							else {
								if (flag.playerCarrying < 0){
									writeln("Pickup!");
									PlaySound(sounds[2]);
									if (server == 1) {
										flag.playerCarrying = player.playerID;
										foreach(Player p; players){
											clearbuffer();
											writebyte(MSG_FLAGPICKUP);
											writebyte(cast(byte)i);
											writebyte(player.playerID);
											sendmessage(p.mySocket);
										}
									} else if (server == 0) {
										clearbuffer();
										writebyte(MSG_FLAGPICKUP);
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
	}

	void movePlayer(Player p) {
		Camera c = p.camera;
		c.moveTranslation(p.lrAmnt*p.speed, 0, -p.fbAmnt*p.speed);

		float movey = 0f;

		float movex = c.position.x - p.x;
		p.dx = movex;
		p.x = c.position.x;
		if (!placeFree(p,0,0,0)){
			if (player.y == 0 || (!placeFree(p,-movex,-.1f,0))){
				movey = builder.dy;
				p.y += movey;
			}
			if (!placeFree(p,0,0,0)){
				p.y -= movey;
				p.x -= movex;
				movey = 0f;
			}
		}

		float movez = c.position.z - p.z;
		p.dz = movez;
		p.z = c.position.z;
		if (!placeFree(p,0,0,0)){
			if (player.y == 0 || (!placeFree(p,0,-.1f,-movez))){
				if (movey == 0f)
					movey = builder.dy;
				else
					movey = 0f;
				
				p.y += movey;
			}
			if (!placeFree(p,0,0,0)){
				p.y -= movey;
				p.z -= movez;
				movey = 0f;
			}
		}
		

		p.dy -= p.gravity;
		p.y += p.dy;
		if (p.y <= 0f){
			p.y = 0f;
			p.dy = 0;
		} else {
			foreach (GameObject o ; renderer.objects) {
				if (o.solid) {
					if (checkCollision(p, o)){
						if (p.dy > 0){
							p.y = o.bottomy - p.height;
						} else if (p.dy < 0){
							p.y = o.topy;
						}
						p.dy = 0;
					}
				}
			}
		}

		c.setTranslation(p.x,p.y+p.eyeHeight,p.z);
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
					if (stage == Stage.WAITING){
						byte pTeam = teams[1] > teams[2] ? 2 : 1;
						Camera c = new Camera();
						Player tempPlayer = new Player(0, 0, 0, &c, pTeam);
						tempPlayer.playerID = playerNum;
						teams[tempPlayer.team]++;
						renderer.register(tempPlayer.getGameObject());
						tempPlayer.mySocket = tempClient;
						playerNum++;
						clearbuffer();
						writebyte(MSG_MYINFO);
						writebyte(tempPlayer.team);
						writebyte(tempPlayer.playerID);
						sendmessage(tempPlayer.mySocket);

						foreach(Player p ; players){
							clearbuffer();
							writebyte(MSG_NEWPLAYER);
							writebyte(p.playerID);
							writebyte(p.team);
							sendmessage(tempPlayer.mySocket);

							clearbuffer();
							writebyte(MSG_NEWPLAYER);
							writebyte(tempPlayer.playerID);
							writebyte(tempPlayer.team);
							sendmessage(p.mySocket);
						}
						clearbuffer();
						writebyte(MSG_NEWPLAYER);
						writebyte(player.playerID);
						writebyte(player.team);
						sendmessage(tempPlayer.mySocket);

						players ~= tempPlayer;
					} else {
						clearbuffer();
						writebyte(MSG_CLOSED);
						sendmessage(tempClient);
					}
				}
				bool discon = false;
				foreach (Player p; players) {
					if (!readsocket(p.mySocket, &userDefined )){
						p.getGameObject().visible = false;
						p.active = false;
						p.removed = true;
						p = null;
						writeln("Player disconnected!");
						discon = true;
					}
				}

				if(discon){
					Array!(Player) temp;
					for(int i = 0; i < players.length; i++) {
						if(players[i].removed == false) {
							temp ~= players[i];
						}
					}
					players = temp;
					writeln(temp.length);
					writeln(players.length);

					foreach (Player p; players) {
						writeln(p.playerID);
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
			case MSG_NEWBLOCK:
				byte pId = readbyte(array);
				float[] xyz = [readfloat(array), readfloat(array), readfloat(array),
					readfloat(array), readfloat(array), readfloat(array)];
				if (server == 1) {
					foreach(Player p; players){
						if (socket != p.mySocket){
							clearbuffer();
							writebyte(MSG_NEWBLOCK);
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
			case MSG_MYINFO:
				byte pTeam = readbyte(array);
				byte myID = readbyte(array);
				player.playerID = myID;
				writeln("You are player ", myID);
				player.setTeam(pTeam);
				return 1+2;
			case MSG_NEWPLAYER:
				byte pId = readbyte(array);
				byte pTeam = readbyte(array);
				writeln("New player: ", pId);
				Camera c = new Camera();
				Player temp = new Player(0,0,0,&c,pTeam);
				temp.playerID = pId;
				renderer.register(temp.getGameObject());
				players ~= temp;
				return 1+2;
			case MSG_DEATH:
				byte pId = readbyte(array);
				Player plyr = findPlayer(pId);
				if (server == 1){
					clearbuffer();
					writebyte(MSG_DEATH);
					writebyte(pId);
					foreach(Player p; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null)
					plyr.die();
				return 2;
			case MSG_RESPAWN:
				byte pId = readbyte(array);
				Player plyr = findPlayer(pId);
				if (server == 1){
					clearbuffer();
					writebyte(MSG_RESPAWN);
					writebyte(pId);
					foreach(Player p ; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null)
					plyr.spawn();
				return 2;
			case MSG_SHOT:
				if (server == 1){
					byte pId = readbyte(array);
					if (pId == player.playerID)
						getShot();
					else {
						foreach (Player p; players){
							if (p.playerID == pId){
								clearbuffer();
								writebyte(MSG_SHOT);
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
			case MSG_UPDATEXYZ:
				Player plyr;
				byte pId = readbyte(array);
				foreach (Player p; players){
					if (p.playerID == pId){
						plyr = p;
						break;
					}
				}
				float newx = readfloat(array);
				float newy = readfloat(array);
				float newz = readfloat(array);

				if (server == 1) {
					clearbuffer();
					writebyte(MSG_UPDATEXYZ);
					writebyte(plyr.playerID);
					writefloat(newx);
					writefloat(newy);
					writefloat(newz);
					foreach (Player p; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null) {
					//plyr.getGameObject().visible = true;
					plyr.camera.position.x = newx;
					plyr.camera.position.y = newy;
					plyr.camera.position.z = newz;
				}
				return 1+1+(4*3);
			case MSG_UPDATECAMERA:
				Player plyr;
				byte pId = readbyte(array);
				foreach (Player p; players){
					if (p.playerID == pId){
						plyr = p;
						break;
					}
				}
				float newHoriz = readfloat(array);
				float newVert = readfloat(array);
				
				if (server == 1) {
					clearbuffer();
					writebyte(MSG_UPDATECAMERA);
					writebyte(plyr.playerID);
					writefloat(newHoriz);
					writefloat(newVert);
					foreach (Player p; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null) {
					//plyr.getGameObject().visible = true;
					plyr.camera.horizontalAngle = newHoriz;
					plyr.camera.verticalAngle = newVert;
					plyr.camera.moveRotation(0,0);
				}
				return 1+1+(4*2);
			case MSG_UPDATEMOVEMENT:
				Player plyr;
				byte pId = readbyte(array);
				foreach (Player p; players){
					if (p.playerID == pId){
						plyr = p;
						break;
					}
				}
				float newlrAmnt = readfloat(array);
				float newfbAmnt = readfloat(array);
				
				if (server == 1) {
					clearbuffer();
					writebyte(MSG_UPDATEMOVEMENT);
					writebyte(plyr.playerID);
					writefloat(newlrAmnt);
					writefloat(newfbAmnt);
					foreach (Player p; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null) {
					//plyr.getGameObject().visible = true;
					plyr.lrAmnt = newlrAmnt;
					plyr.fbAmnt = newfbAmnt;
				}
				return 1+1+(4*2);
			case MSG_JUMP:
				Player plyr;
				byte pId = readbyte(array);
				foreach (Player p; players){
					if (p.playerID == pId){
						plyr = p;
						break;
					}
				}
				
				if (server == 1) {
					clearbuffer();
					writebyte(MSG_JUMP);
					writebyte(plyr.playerID);
					foreach (Player p; players){
						if (p.mySocket != socket){
							sendmessage(p.mySocket, false);
						}
					}
					clearbuffer();
				}
				if (plyr !is null) {
					//plyr.getGameObject().visible = true;
					plyr.jump();
				}
				return 1+1;
			case MSG_BEGINBUILD:
				beginBuildPhase();
				return 1;
			case MSG_FLAGRESET: // Reset flag to home
				byte flagNum = readbyte(array);
				if (flagNum != 1 && flagNum != 2)
					flagNum = 0;
				
				if (flagNum != 0 && ctfFlags[flagNum].playerCarrying < 0){
					ctfFlags[flagNum].reset();
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(MSG_FLAGRESET);
							writebyte(flagNum);
							sendmessage(p.mySocket);
						}
					}
				}
				return 1+1;
			case MSG_FLAGPICKUP: // Pickup flag
				byte flagNum = readbyte(array);
				byte pId = readbyte(array);

				if (ctfFlags[flagNum].playerCarrying < 0){
					writeln("Pickup flag!");
					ctfFlags[flagNum].playerCarrying = pId;
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(MSG_FLAGPICKUP);
							writebyte(flagNum);
							writebyte(pId);
							sendmessage(p.mySocket);
						}
					}
				}
				return 3;
			case MSG_FLAGDROP: // Drop flag
				byte flagNum = readbyte(array);

				if (ctfFlags[flagNum].playerCarrying >= 0){
					ctfFlags[flagNum].playerCarrying = -1;
					if (server == 1){
						foreach(Player p; players){
							clearbuffer();
							writebyte(MSG_FLAGDROP);
							writebyte(flagNum);
							sendmessage(p.mySocket);
						}
					}
				}
				return 2;
			case MSG_FLAGSCORE: // Score
				byte flagNum = readbyte(array);
				
				int teamScore = flagNum == 1 ? 2 : 1;
				scoreForTeam(teamScore);
				ctfFlags[flagNum].reset();
				if (server == 1){
					foreach (Player p ; players){
						clearbuffer();
						writebyte(MSG_FLAGSCORE);
						writebyte(flagNum);
						sendmessage(p.mySocket);
					}
				}
				return 2;
			case MSG_BEGINGAMEPLAY:
				beginGameplay();
				return 1;
			case MSG_CLOSED:
				writeln("The server rejected your connection, likely because the match has already started.");
				running = false;
				return 1;
			default:
				writeln("Unsupported message: ", MSG_ID);
				return 1;
		}
	}

	static void scoreForTeam(int team){
		PlaySound(sounds[0]);
		writeln("Score from team ", team == 1 ? "red": "blue");
		score[team]++;
		writeln("Score is RED ",score[1],", BLUE ",score[2]);
	}

	static void beginBuildPhase(){
		writeln("Begin build phase!");
		builder.startx = player.team == 1 ? -25*builder.dx : 24*builder.dx;
		builder.startz = 0;
		for(int i = 1; i < ctfFlags.length; i++){
			GameObject flag = ctfFlags[i].getGameObject();
			flag.x = ctfFlags[i].team == 1 ? -25*builder.dx : 24*builder.dx;
			flag.z = 0;
			flag.y = builder.dy*2;
			flag.updateMatrix();
			addBlock(flag.x-builder.dx,
					flag.y-builder.dy*2,
					flag.z+builder.dz,
					flag.x+builder.dx*2,
					flag.y-builder.dy,
					flag.z-builder.dz*2,
					flag.r,
					0,
					flag.b);
			ctfFlags[i].lock();
		}
		builder.startx -= player.team == 1 ? 2*builder.dx : -2*builder.dx;
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

		window.pause(frameDelay - time);
	}

	static Player findPlayer(int pId){
		foreach (Player p; players){
			if (p.playerID == pId){
				return p;
			}
		}
		if (pId == player.playerID)
			return player;
		return null;
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
		player.spawn();
		player.getGameObject.visible = false;
		player.update();
		foreach (Player p ; players){
			Flag mFlag = ctfFlags[p.team];
			p.x = mFlag.lockx;
			p.z = mFlag.lockz;
			p.y = mFlag.locky;
			p.startx = p.x;
			p.starty = p.y;
			p.startz = p.z;
			p.camera.setTranslation(p.x,p.y+p.eyeHeight,p.z);
			p.getGameObject.visible = true;
			p.update();
		}
		builder.getGameObject().visible = false;
	}

	void swapMode(){
		if (stage == Stage.MAP_MAKER){
			beginGameplay();
		} else {
			stage = Stage.MAP_MAKER;
			builder.getGameObject().visible = true;
			builder.dir = 0;
			camera.setTranslation(builder.startx + 0f, builder.starty + 9f, builder.startz + 11f);
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
		camera.position.y += 1f;
	}
	void moveCameraForward(){
		if (builder.dir == 0)
			camera.position.z -= 1f;
		else if (builder.dir == 1)
			camera.position.x -= 1f;
		else if (builder.dir == 2)
			camera.position.z += 1f;
		else if (builder.dir == 3)
			camera.position.x += 1f;
	}
	void moveCameraDown(){
		camera.position.y -= 1f;
	}
	void moveCameraBack(){
		if (builder.dir == 0)
			camera.position.z += 1f;
		else if (builder.dir == 1)
			camera.position.x += 1f;
		else if (builder.dir == 2)
			camera.position.z -= 1f;
		else if (builder.dir == 3)
			camera.position.x -= 1f;
	}

	static void getShot() {
		if (!player.isAlive)
			return;
		player.hp--;
		PlaySound(sounds[3]);
		if (player.hp<1){
			player.die();
			clearbuffer();
			renderer.isDead = true;
			writebyte(MSG_DEATH);
			writebyte(player.playerID);
			if (server == 0)
				sendmessage(getSocket());
			else if (server == 1){
				foreach(Player p ; players){
					sendmessage(p.mySocket, false);
				}
			}
			clearbuffer();

			byte otherFlagInd = player.team == 1 ? 2 : 1;
			Flag otherFlag = ctfFlags[otherFlagInd];
			if (otherFlag.playerCarrying == player.playerID){
				otherFlag.playerCarrying = -1;
				if (server == 1){
					foreach(Player p; players){
						clearbuffer();
						writebyte(MSG_FLAGDROP);
						writebyte(otherFlagInd);
						sendmessage(p.mySocket);
					}
				} else if (server == 0){
					clearbuffer();
					writebyte(MSG_FLAGDROP);
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
		if (!player.isAlive())
			return;
		GameObject shot = checkCollisions();
		foreach (Player p; players){
			if (p.getGameObject() == shot){
				writeln("You shot player ", p.playerID, "!");
				PlaySound(sounds[1]);
				if (server == 1){
					clearbuffer();
					writebyte(MSG_SHOT);
					sendmessage(p.mySocket);
				} else if (server == 0) {
					clearbuffer();
					writebyte(MSG_SHOT);
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

	void rotateViewLeft(){
		camera.moveRotation(-PI/2, 0);
		builder.dir--;
		if (builder.dir < 0)
			builder.dir = 3;
		float dx = camera.position.x - builder.startx;
		float dz = camera.position.z - builder.startz;
		camera.position.x = builder.startx - dz;
		camera.position.z = builder.startz + dx;
	}

	void rotateViewRight(){
		camera.moveRotation(PI/2, 0);
		builder.dir++;
		if (builder.dir > 3)
			builder.dir = 0;
		float dx = camera.position.x - builder.startx;
		float dz = camera.position.z - builder.startz;
		camera.position.x = builder.startx + dz;
		camera.position.z = builder.startz - dx;
	}

	void moveBlockLeft(){
		if (builder.dir == 0)
			builder.left();
		else if (builder.dir == 1)
			builder.down();
		else if (builder.dir == 2)
			builder.right();
		else if (builder.dir == 3)
			builder.up();
		//camera.moveTranslation(-.05f,0f,0f);
	}
	void moveBlockRight(){
		if (builder.dir == 0)
			builder.right();
		else if (builder.dir == 1)
			builder.up();
		else if (builder.dir == 2)
			builder.left();
		else if (builder.dir == 3)
			builder.down();
		//camera.moveTranslation(.05f,0f,0f);
	}
	void moveBlockUp(){
		if (builder.dir == 0)
			builder.up();
		else if (builder.dir == 1)
			builder.left();
		else if (builder.dir == 2)
			builder.down();
		else if (builder.dir == 3)
			builder.right();
		//camera.moveTranslation(0f,0.05f,0f);
	}
	void moveBlockDown(){
		if (builder.dir == 0)
			builder.down();
		else if (builder.dir == 1)
			builder.right();
		else if (builder.dir == 2)
			builder.up();
		else if (builder.dir == 3)
			builder.left();
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
					foreach(Player p; players){
						clearbuffer();
						writebyte(MSG_NEWBLOCK);
						writebyte(player.playerID);
						for (int i = 0; i < 6; i++)
							writefloat(coords[i]);
						sendmessage(p.mySocket);
					}
				} else if (server == 0){
					clearbuffer();
					writebyte(MSG_NEWBLOCK);
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
        // Font loading
        //GameObject got = new GameObject(x1,y1,z1,x2,y2,z2,true, new Texture("blankd".dup, 1,1,0));
        GameObject got = new GameObject(x1,y1,z1,x2,y2,z2);
        //GameObject got = new GameObject(x1,y1,z1,x2,y2,z2 ,true, resman.getTexture("simpleTex.png".dup));
        got.visible = true;
        got.solid = true;
        got.setColor(r, g, b);
        got.updateMatrix();
        renderer.register(got);
	}

    GameObject checkCollisions()
    {

        GameObject closestCol = null;
        Vector direction = camera.direction;
        Vector position = camera.position;
        int closestIndex = -100;

        int num = 0;
        foreach (GameObject obj; renderer.objects) {
        	if (!obj.visible)
        		continue;
        	if (obj == player.getGameObject())
        		continue;
            // This should be cleaner, but you know, hackathon. Time.
            //writeln("Checking object  ", num);
            for (float i = 0; i > -100; i-=.1) {
                float x = position.x + direction.x * i; 
                float y = position.y + direction.y * -i; 
                float z = position.z + direction.z * i; 

                if (obj.leftx == 0) // Not a box (it's the floor at 18)
                    break;

                float x1 = obj.leftx+obj.x; // Left face x
                float x2 = obj.rightx+obj.x; // Right face x
                float y1 = obj.topy+obj.y; // Top face y
                float y2 = obj.bottomy+obj.y; // Bottom face y
                float z1 = obj.frontz+obj.z; // Front face z
                float z2 = obj.backz+obj.z; // Back face z

                //float x1 = obj.vBufferData[75]+obj.x; // Left face x
                //float x2 = obj.vBufferData[93]+obj.x; // Right face x
                //float y1 = obj.vBufferData[19]+obj.y; // Top face y
                //float y2 = obj.vBufferData[55]+obj.y; // Bottom face y
                //float z1 = obj.vBufferData[2]+obj.z; // Front face z
                //float z2 = obj.vBufferData[38]+obj.z; // Back face z
                
                if (    abs(x - ((x1+x2)/2) ) < abs( (x1-x2)/2)
                        &&  abs(y - ((y1+y2)/2) ) < abs( (y1-y2)/2)
                        &&  abs(z - ((z1+z2)/2) ) < abs( (z1-z2)/2) ) {
                    //writeln("A collision with object ", num);
                    if (i > closestIndex) {
                        closestIndex = to!int(i);
                        closestCol = obj;
                    }
                    break;
                }
            }
            num++;
        }
        //float x = position.x + direction.x * closestIndex; 
        //float y = position.y + direction.y * -closestIndex; 
        //float z = position.z + direction.z * closestIndex; 
        //GameObject hitObj = new GameObject(x-.1,y-.1,z-.1,x+.1,y+.1,z+.1);
        //hitObj.visible = true;
        //renderer.register(hitObj);
        return closestCol;
	}
}
