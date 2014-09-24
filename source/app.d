import std.stdio;
import core.thread;
import std.string;

import Window;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.ttf;
import derelict.sdl2.mixer;
import derelict.sdl2.image;

import networking;
import GameManager;
bool running;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2Image.load();

    if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_JOYSTICK) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }

    int server = -1;
    
    writeln("Server or client or no networking? s/c/n");
    writeln("If client, optional server IP parameter (c 127.0.0.1)");
    char[] buf;
    stdin.readln(buf);
    string ip_addr;
    switch (buf[0]){
        case 's':
        ip_addr = "";
        server = 1;
        break;
        case 'c':
        server = 0;
        ip_addr = chompPrefix(chompPrefix(buf, "c"), " ").idup;
        break;
        default:
        server = -1;
        break;
    }

    Window window = new Window("HackGT - blankd");
    window.init();
    // Has to reload after we have a context
    DerelictGL3.reload();

    new GameManager(&window, server, ip_addr);

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

