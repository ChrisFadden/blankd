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

import networking;
import GameManager;

bool running;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();

    Window window = new Window("HackGT - blankd");
    window.init();
    // Has to reload after we have a context
    DerelictGL3.reload();

    new GameManager(&window);

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

void basic(byte* array) {
    float a = readfloat(array);
    writeln("Received ", a);
    running = false;
}

