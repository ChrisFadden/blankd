import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

class Texture {
    GLuint texID;
    char[] name;
    uint width;
    uint height;
    void* texData;

    this(char[] name) {
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Before texture error!", error);
        this.name = name;

        GLenum textureFmt;
        GLint numColors;
        SDL_Surface* surface = IMG_Load(name.ptr);
        if (!surface) {
            writeln("Could not load ", name);
            texID = 0;
        }

        numColors = surface.format.BytesPerPixel;
        if (numColors == 4) {
            //alpha
            if (surface.format.Rmask == 0xFF)
                textureFmt = GL_RGBA;
            else
                textureFmt = GL_BGRA;
        } else {
            if (numColors == 3) {
                // no alpha
                if (surface.format.Rmask == 0xFF)
                    textureFmt = GL_RGB;
                else
                    textureFmt = GL_BGR;
            } else {
                //bad bad
                texID = 0;
            }
        }

        width = surface.w;
        height = surface.h;

        glGenTextures(1, &texID);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texID);

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexImage2D(GL_TEXTURE_2D, 0, numColors, width, height, 0, textureFmt, GL_UNSIGNED_BYTE, surface.pixels);

        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Texture error!", error);
    }

    char[] getName(){
        return name;
    }
}
