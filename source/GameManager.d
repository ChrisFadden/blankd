import std.stdio;
import core.thread;
import std.string;
import std.math;

import Window;
import Renderer;
import gameobject;
import std.conv;
import ObjLoader;
import Player;

import networking;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import LoadWav;

class GameManager {

	static Camera camera;
	float[] targetCamera = [0, 4, 1];
    static Renderer renderer;
    float lrAmnt;
    float fbAmnt;
    float udAmnt;
    float scanHoriz;
    float scanVert;

    static TCPsocket[] sockets;
    static int socketNum;

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
		camera.moveRotation(0f,0);
    	renderer = new Renderer(win, &camera);
    	this.server = server;

    	char* music = cast(char*)"music	.wav";
    	//loadWav(music);

    	lrAmnt = 0;
    	fbAmnt = 0;
    	udAmnt = 0;
    	scanHoriz = 0;
    	scanVert = 0;

    	window = win;

    	player = new Player(0, 0, 0, &camera);

	    builder = new BlockBuilder(-1.0, 0.0, -4.0);
	    GameObject b = builder.getGameObject();
	    b.visible = true;
	    b.setRGB(1,1,0.9);
	    renderer.register(b);

	    GameObject floor = new GameObject(-80,-80,160,160);
	    floor.visible = true;
	    floor.setRGB(.2f,.9f,.5f);
	    renderer.register(floor);


	    /*
	    go1 = new GameObject(-1.0, -1.0, 1.0, 1.0, 1.0, -1.0);
	    go1.visible = true;
	    go1.x = 0.0;
	    go1.y = 0.0;
	    go1.z = -3.0;
        go1.setRGB(0.5, 1.0, 0.5);
        go1.updateMatrix();
	    renderer.register(go1);
	    */
	    
	    
	    
	    

	    //ObjLoader objloader = new ObjLoader();
    	//objloader.open("block.obj", go1);
    	

    	
    	//renderer.register(go1);
    	
    	

	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;

	    SDL_JoystickEventState(SDL_ENABLE);
	    joystick = SDL_JoystickOpen(0);

	    stage = Stage.MAP_MAKER;

	    if (server == 1) {
	    	SDLNet_InitServer(1234, 20);
	    	sockets = new TCPsocket[20];
	    	socketNum = 0;
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

	void step(float deltaTime){
		frameTime = SDL_GetTicks();

		SDL_Event event;
		if (stage == Stage.MAP_MAKER){
			handleMapMakerInput(&event);
			camera.moveTranslation(lrAmnt,udAmnt,-fbAmnt);
		}
		else{
			handleGameplayInput(&event);
			camera.moveTranslation(lrAmnt, 0, -fbAmnt);
			player.x = camera.position.x;
			player.z = camera.position.z;
			camera.position.y = player.y + player.height;
			camera.moveRotation(-scanHoriz/20f, -scanVert/20f);
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
					sockets[socketNum] = tempClient;
					socketNum++;
					writebyte(2);
					writefloat(117f);
					sendmessage(tempClient);
				}
				for (int i = 0; i < socketNum; i++) {
					readsocket(sockets[i], &userDefined );
				}
			}
		} else if (server == 0){
			if (checkSockets() > 0){
				readsocket(getSocket(), &userDefined);
			}
		}
	}

	static void userDefined(byte** array, TCPsocket socket){
		writeln("USER DEFINED");
		byte MSG_ID = readbyte(array);
		switch(MSG_ID) {
			case 1:
				writeln("Adding block.");
				float[] xyz = [readfloat(array), readfloat(array), readfloat(array),
					readfloat(array), readfloat(array), readfloat(array)];
				writeln(xyz);
				if (server == 1) {
					writeln("Sending block to other clients.");
					for (int c = 0; c < socketNum; c++){
						if (socket != sockets[c]){
							clearbuffer();
							writebyte(1);
							for (int i = 0; i < 6; i++)
								writefloat(xyz[i]);
							sendmessage(sockets[c]);
						}
					}
				}
				addBlock(xyz[0], xyz[1], xyz[2], xyz[3], xyz[4], xyz[5], 1f, .5f, .5f);
				break;
			case 2:
				writeln(readfloat(array));
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
		stage = Stage.GAMEPLAY;
		player.x = camera.position.x;
		player.z = camera.position.z;
		player.y = 0;
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
					for (int c = 0; c < socketNum; c++){
						clearbuffer();
						writebyte(1);
						for (int i = 0; i < 6; i++)
							writefloat(coords[i]);
						sendmessage(sockets[c]);
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
        got.setRGB(r, g, b);
        got.updateMatrix();
        renderer.register(got);
	}

	void handleGameplayInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYAXISMOTION:
				writeln(event.jaxis.axis);
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
						default:
						break;
					}
				break;
				default:
				break;
			}
		}
	}

	void checkCollisions()
	{
		//setPerspectiveMatrix(60.0, 1280.0/720.0, 1.0, 100.0)
		float window_width = 1280.0;
		float window_height = 720.0;
		float znear = 1.0;
		//float zfar = 100.0;
		
		int window_y = to!int(window_height/2.0f);
		double norm_y = double(window_y)/double(window_height/2.0f);
		int window_x = to!int((window_width)/2.0f);
		double norm_x = double(window_x)/double(window_width/2.0f);

		float[4] ray_vec = [norm_x, norm_y, -znear, 0.0f];
		
		float[16] mat = builder.gameObject.modelMatrix.matrix;
		Matrix m = new Matrix;
		m.matrix = mat;
		m.matrix[0] = -mat[0];
        m.matrix[5] = -mat[5];
        m.matrix[10] = -mat[10];
		
		float[16] cmat = camera.viewMatrix.matrix;
		Matrix v = new Matrix;
		v.matrix[0] = -cmat[0];
        v.matrix[5] = -cmat[5];
        v.matrix[10] = -cmat[10];

        Matrix temp = m*v;

        writeln(ray_vec);
        writeln(temp*ray_vec);
	}
}
