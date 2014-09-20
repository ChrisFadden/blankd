import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;
import blankdmod.myo.functions;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.ttf;

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

    TTF_Font *font;

	this(Window* win) {
		camera = new Camera();
    	renderer = new Renderer(win, &camera);

    	window = win;

    	go1 = new GameObject;
	    go1.visible = true;
	    go1.x = 1.0;
	    go1.y = 1.0;
	    go1.z = 0.0;
        go1.updateMatrix();
	    renderer.register(go1);

	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;

	    SDL_JoystickEventState(SDL_ENABLE);
	    joystick = SDL_JoystickOpen(0);


	    run();
	}

	void run(){
		writeln("Go!");
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
		handleInput(&event);
		
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

	void handleInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYBUTTONDOWN:
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
