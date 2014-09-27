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

    //Settings settings = {1080, 1920, -1, 10, "127.0.0.1"};
    Settings settings = {720, 1280, -1, 10, "127.0.0.1"};
    Window window = new Window("HackGT - blankd", settings.windowHeight, settings.windowWidth);
    window.init();

    // Has to reload after we have a context
    DerelictGL3.reload();
    
    Renderer renderer = new Renderer(window);
    Menu menu = new Menu(window, renderer, settings);
    settings = menu.run();

    if (settings.server != -2) //quit
        new GameManager(window, renderer, settings);

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

