import std.stdio;
import core.thread;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

class Window {
    string title; 
    uint windowX = 1280;
    uint windowY = 720;
    SDL_Window *window;
    SDL_GLContext glcontext;

    this(string title) {
        this.title = title;
    }

    void init() {
        if (SDL_Init(SDL_INIT_VIDEO) < 0) {
            writeln("SDL2 failed to init: ", SDL_GetError());
            return;
        }

        version (OSX) {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
        } else {
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
        }

        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

        window = SDL_CreateWindow(cast(char*)title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
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
    }

    void flip() {
        SDL_GL_SwapWindow(window);
    }

    void pause(uint ms) {
        SDL_Delay(ms);
    }
    
    void quit() {
        SDL_GL_DeleteContext(glcontext);
        SDL_DestroyWindow(window);
    }
}
