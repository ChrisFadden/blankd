import std.stdio;
import core.thread;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

class Window {
    string title; 
    uint windowWidth = 1280;
    uint windowHeight = 720;
    SDL_Window *window;
    SDL_GLContext glcontext;

    this(string title, int width, int height) {
        this.title = title;
        windowWidth = width;
        windowHeight = height;
    }

    void init() {

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
                windowWidth, windowHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
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

        SDL_ShowCursor(0);
    }

    uint width() {
        return windowWidth;
    }

    uint height() {
        return windowHeight;
    }

    void resize(int width, int height) {
        windowWidth = width;
        windowHeight = height;
        SDL_SetWindowSize(window, width, height);
        glViewport(0,0,width,height);
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
