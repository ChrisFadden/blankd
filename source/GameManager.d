import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;
import std.conv;
import ObjLoader;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

class GameManager {

	Camera camera;
    Renderer renderer;

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

    BlockBuilder builder;

	this(Window* win) {
		camera = new Camera();
		camera.setTranslation(0f,0f,1f);
    	renderer = new Renderer(win, &camera);

    	window = win;

    	/*
    	go1 = new GameObject(-1.0, -1.0, 1.0, 1.0, 1.0, -1.0);
	    go1.visible = true;
	    go1.x = 0.0;
	    go1.y = 0.0;
	    go1.z = -3.0;
        go1.setRGB(0.2, 1.0, 0.4);
        go1.updateMatrix();
	    renderer.register(go1);
	    */
	    
	    

	    //ObjLoader objloader = new ObjLoader();
    	//objloader.open("block.obj", go1);
    	

    	builder = new BlockBuilder(-1.0, -1.0, -4.0);
    	builder.visible = true;
    	builder.setRGB(0.6, 1.0, 0.9);
    	renderer.register(builder);
    	
    	
    	

	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;

	    SDL_JoystickEventState(SDL_ENABLE);
	    joystick = SDL_JoystickOpen(0);

	    stage = Stage.MAP_MAKER;

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
		if (stage == Stage.MAP_MAKER)
			handleMapMakerInput(&event);
		
	}

	void draw(){
		renderer.draw();


		fpsCounter++;
		if (SDL_GetTicks() - fpsTime >= 1000){
			fps = fpsCounter;
			fpsCounter = 0;
			fpsTime = SDL_GetTicks();
			debug writeln("FPS: ", fps);
		}

		int time = cast(int)(SDL_GetTicks() - frameTime);
		if (frameDelay <= time)
			time = 0;

		(*window).pause(frameDelay - time);
	}

	void clean(){

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
	void placeBlock(){}


	void handleMapMakerInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYBUTTONDOWN:
					debug writeln("Button ", event.jbutton.button);
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
						// Left-Right
					} if (event.jaxis.axis == 1) {
						// Up-down
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
				case SDL_MOUSEMOTION:
					int x = event.motion.x;
					int y = event.motion.y;
					SDL_WarpMouseInWindow(window.window, window.width()/2, window.height()/2);
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
						case SDLK_i:
							moveCameraUp();
							break;
						case SDLK_j:
							moveCameraLeft();
							break;
						case SDLK_k:
							moveCameraDown();
							break;
						case SDLK_l:
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
	}
}

class BlockBuilder : GameObject{
	float startx, starty, startz;
	float dx = 2.0;
	float dy = 1.0;
	float dz = 2.0;
	float width;
	float length;
	float height;

	this(float startx, float starty, float startz) {
		super(startx,starty,startz,startx+dx,starty+dy,startz-dz);
		this.startx = startx;
		this.starty = starty;
		this.startz = startz;
		width = dx;
		length = dz;
		height = dy;
		updateMesh();
	}

	void right() {
		width += dx;
		updateMesh();
	}

	void left() {
		if (width > dx)
			width -= dx;
		else
			startx -= dx;
		updateMesh();
	}

	void up() {
		length += dz;
		updateMesh();
	}

	void down() {
		if (length > dz)
			length -= dz;
		else
			startz += dz;
		updateMesh();
	}

	void raise() {
		height += dy;
		updateMesh();
	}

	void lower() {
		if (height > dy)
			height -= dy;
		updateMesh();
	}

	override
	void updateMesh() {
		setVertexBuffer(startx,starty,startz,startx+width,starty+height,startz-length);
		super.updateMesh();
	}
}
