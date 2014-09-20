import std.stdio;
import core.thread;
import std.string;

import Window;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.ttf;

import networking;
import GameManager;
bool running;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_JOYSTICK) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }

    writeln("Server or client or no networking? s/c/n");
    char[] buf;
    stdin.readln(buf);
    int server;
    switch (buf[0]){
        case 's':
        server = 1;
        break;
        case 'c':
        server = 0;
        break;
        default:
        server = -1;
        break;
    }

    Window window = new Window("HackGT - blankd");
    window.init();
    // Has to reload after we have a context
    DerelictGL3.reload();

    new GameManager(&window, server);

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

