import std.stdio;
import core.thread;
import std.string;
import std.conv;
import std.file;

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
    Settings settings = {720, 1280, -1, 10, "127.0.0.1", "debug"};
    writeln("Initial values");
    readSettings(&settings);
    Window window = new Window("HackGT - blankd", settings.windowWidth, settings.windowHeight);
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

void readSettings(Settings* s){
    if(!exists("settings.conf")) {
        writeFile(s);
    }
    else {
        File f = File("settings.conf", "r");
        string ln;
        string attrib;
        while(!f.eof()) {
            ln = chomp(f.readln());
            if(ln.length > 0) {
                attrib = munch(ln, "versionheightwidth");
                ln = strip(ln);
                if(attrib == "height") {
                    s.windowHeight = to!int(ln);
                }
                if(attrib == "width") {
                    s.windowWidth = to!int(ln);
                }
            }
        }
        f.close();
    }
}

void writeFile(Settings* s) {
    File f = File("settings.conf", "w");
    f.writeln("version ", s.buildNum);
    f.writeln("height ", s.windowHeight);
    f.writeln("width ", s.windowWidth);
    f.close();
}