import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;


import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.mixer;
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
}
