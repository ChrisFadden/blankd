import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;
import blankdmod.myo.functions;
import ObjLoader;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

class GameManager {

	Camera camera;
    Renderer renderer;

    int frameDelay = 1000/61;

    Window* window;

    GameObject go1;

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

	this(Window* win) {
		camera = new Camera();
		camera.setTranslation(0f,0f,0f);
    	renderer = new Renderer(win, &camera);

    	window = win;

    	go1 = new GameObject(-1.0, -1.0, 1.0, 1.0, 1.0, -1.0);
	    go1.visible = true;
	    go1.x = 0.0;
	    go1.y = 0.0;
	    go1.z = -3.0;
        go1.setRGB(0.2, 1.0, 0.4);
        go1.updateMatrix();
	    renderer.register(go1);

	    //ObjLoader objloader = new ObjLoader();
    	//objloader.open("block.obj", go1);
    	go1.printVerts();

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
		//moduleFunc();
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
			writeln("FPS: ", fps);
		}

		int time = cast(int)(SDL_GetTicks() - frameTime);
		if (frameDelay <= time)
			time = 0;

		(*window).pause(frameDelay - time);
	}

	void clean(){

	}

	void moveBlockLeft(){
		camera.moveTranslation(-.05f,0f,0f);
	}
	void moveBlockRight(){
		camera.moveTranslation(.05f,0f,0f);
	}
	void moveBlockUp(){
		camera.moveTranslation(0f,0.05f,0f);
	}
	void moveBlockDown(){
		camera.moveTranslation(0f,-0.05f,0f);
	}
	void raiseBlock(){}
	void lowerBlock(){}
	void placeBlock(){}


	void handleMapMakerInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYBUTTONDOWN:
					writeln("Button ", event.jbutton.button);
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
						default:
						break;
					}
				break;
				default:
				break;
			}
		}
	}
}
