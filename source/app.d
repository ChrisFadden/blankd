import std.stdio;
import core.thread;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import gameobject;

import networking;

immutable char* title = "HackGT - blankd";
immutable uint windowX = 1280;
immutable uint windowY = 720;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();

    SDLNet_InitServer(1234, 20);

    SDL_Window *window;
    SDL_GLContext glcontext;
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        writeln("SDL2 failed to init: ", SDL_GetError());
        return;
    }

    version (OSX) {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    } else {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    }

    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

    window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                           windowX, windowY, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    if (!window) {
        writeln("Failed to create SDL window: ", SDL_GetError());
        return;
    }

    SDL_ClearError();
    glcontext = SDL_GL_CreateContext(window);
    const char * error = SDL_GetError();
    if (*error != '\0') {
        printf("SDL Error creating OpenGL context: %s", error);
        return;
    }

    DerelictGL3.reload();

    // GL Stuff


    SDL_GL_SwapWindow(window);

    // End

    SDL_Delay(2000);

    GameObject go1 = new GameObject;
    go1.visible = true;
    writeln(go1.visible);
    go1.coords[0] = 0.0;
    go1.coords[1] = 1.0;
    go1.coords[2] = 2.0;
    writeln(go1.coords);

    //Finish and quit
    SDL_GL_DeleteContext(glcontext);
    SDL_DestroyWindow(window);
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

