import std.stdio;
import core.thread;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.ttf;
import derelict.sdl2.mixer;
import derelict.sdl2.image;

import networking;
import Window;
import Menu;
import GameManager;
bool running;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();
    DerelictSDL2Mixer.load();
    DerelictSDL2Image.load();
    DerelictSDL2ttf.load();

    if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_JOYSTICK) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }

    TTF_Init();

    Window window = new Window("HackGT - blankd");
    window.init();

    // Has to reload after we have a context
    DerelictGL3.reload();
    
    Renderer renderer = new Renderer(window);
    Menu menu = new Menu(window, renderer);
    Settings settings = menu.run();
    //int server = -1;
    
    //writeln("Server or client or no networking? s/c/n");
    //writeln("If client, optional server IP parameter (c 127.0.0.1)");
    //char[] buf;
    //stdin.readln(buf);
    //string ip_addr;
    //switch (buf[0]){
        //case 's':
        //ip_addr = "";
        //server = 1;
        //break;
        //case 'c':
        //server = 0;
        //ip_addr = chompPrefix(chompPrefix(buf, "c"), " ").idup;
        //break;
        //default:
        //server = -1;
        //break;
    //}

    if (settings.server != -2) //quit
        new GameManager(window, renderer, settings);

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

