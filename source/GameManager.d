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

	this(Window* win) {
		camera = new Camera();
    	renderer = new Renderer(win, &camera);

    	window = win;

    	go1 = new GameObject;
	    go1.visible = true;
	    writeln(go1.visible);
	    go1.coords[0] = 0.0;
	    go1.coords[1] = 1.0;
	    go1.coords[2] = 2.0;
	    writeln(go1.coords);
	    renderer.register(go1);

	    run();
	    fpsTime = SDL_GetTicks();
	    fps = 1;
	    fpsCounter = 0;
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