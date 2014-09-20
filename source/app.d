import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

//import networking;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    //DerelictSDL2Net.load();

    Window window = new Window("HackGT - blankd");
    window.init();
    // Has to reload after we have a context
    DerelictGL3.reload();

    Camera camera = new Camera();
    Renderer renderer = new Renderer(window, camera);

    GameObject go1 = new GameObject;
    go1.visible = true;
    writeln(go1.visible);
    go1.coords[0] = 0.0;
    go1.coords[1] = 1.0;
    go1.coords[2] = 2.0;
    writeln(go1.coords);
    renderer.register(go1);
    renderer.draw();
    window.pause(2000);

    //SDLNet_InitServer(1234, 20);


    //Finish and quit
    window.quit();
    //freesockets();
    //SDLNet_Quit();
    SDL_Quit();
}

