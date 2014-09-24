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
import Texture;

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
	Texture[] textures;

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

	Texture getTexture(string name) 
	{
		for(int i = 0; i < textures.length; i++)
		{
			if(icmp(textures[i].getName(), name) == 0)
			{
				return textures[i];
			}
		}
		return null;
	}

	void loadTexture(string name)
	{
		bool exists = false;
		foreach(Texture o; textures)
		{
			if(icmp(o.getName(), name) == 0)
			{
				exists = true;
				break;
			}
		}

		if(!exists)
		{
			textures ~= new Texture(name.dup);
		}
	}
}
