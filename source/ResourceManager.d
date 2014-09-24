import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;


import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;
import ShaderProgram;
import LoadWav;

static ResourceManager getResourceManager() {
    static ResourceManager instance;
    if (instance)
        return instance;
    instance = new ResourceManager();
    return instance;
}

class ResourceManager {

	ShaderProgram[bool] shaders;
	Mix_Chunk*[] sounds; 
    TTF_Font*[uint] fonts;

	/*
	** The other items like textures and sounds can go here too!
	*/

	this()
	{
		shaders[true] = new ShaderProgram(true);
		shaders[false] = new ShaderProgram(false);
    }

	~this()
	{}

	ShaderProgram getShader(bool key)
	{
        return shaders[key];
	}

	void loadSound(char[] fileName)
	{
		sounds ~= loadWav(fileName.ptr);
	}

	Mix_Chunk*[] getSound()
	{
		return sounds;
	}

    TTF_Font* getFont() {
        uint size = 108; // Crashes if we load more than once, we'll only do one high res size :(
        if ((size in fonts) == null) {
            writeln("Loading font of size ", size);
            fonts[size] = TTF_OpenFont("mplus-1c-light.ttf".dup.ptr, size);
            if (!fonts[size]) {
                string err = to!string(cast(char*)TTF_GetError());
                writeln("TTF Error: ", err);
            }
        }
        return fonts[size];
    }
}
