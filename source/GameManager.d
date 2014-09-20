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

    GameObject go3;

    BlockBuilder builder;

	this(Window* win) {
		camera = new Camera();
		camera.setTranslation(0f,1.5f,1f);
		//camera.moveRotation(45,0,0);
    	renderer = new Renderer(win, &camera);

    	window = win;

    	/*
    	GameObject go1;

    	go1 = new GameObject(-1, -1, 1, 1, 1, -1);
	    go1.visible = true;
	    go1.x = 3.0;
	    go1.y = 0.0;
	    go1.z = -3.0;
        go1.setRGB(1.0, 0.5, 1.0);
        go1.updateMatrix();
	    renderer.register(go1);
    	
    	GameObject go2 = new GameObject(-1, -1, 1, 1, 1, -1);
    	//go2.problematic = true;
    	go2.x = 1;
    	go2.y = 0;
    	go2.z = -3;
    	go2.updateMatrix();
    	go2.setRGB(0.5, 1.0, 0.5);
    	renderer.register(go2);

    	go3 = new GameObject(-1.0, -1.0, 1.0, 1.0, 1.0, -1.0);
	    go3.visible = true;
	    go3.x = -1.0;
	    go3.y = 0.0;
	    go3.z = -3.0;
        go3.setRGB(1.0, 0.5, 0.5);
        go3.updateMatrix();
	    renderer.register(go3);

	    GameObject go4 = new GameObject(-1, -1, 3, 1, 1, 1);
	    go4.visible = true;
	    go4.x = -3.0;
	    go4.y = 0.0;
	    go4.z = -3.0;
        go4.setRGB(0.9, 0.9, 0.9);
        go4.updateMatrix();
	    renderer.register(go4);
	    */
	    

	    builder = new BlockBuilder(-1.0, -1.0, -4.0);
	    GameObject b = builder.getGameObject();
	    b.visible = true;
	    b.setRGB(1,1,0.9);
	    renderer.register(b);


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
	void placeBlock(){
		if (builder.placing){
			renderer.register(builder.place());
			//renderer.reregister(builder);
		}
		else
			builder.beginPlace();
	}


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
