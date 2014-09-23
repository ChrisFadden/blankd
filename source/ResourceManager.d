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

class ResourceManager {
	ShaderProgram[] shaders;
	Mix_Chunk*[] sounds; 
	/*
	** The other items like textures and sounds can go here too!
	*/

	this()
	{}

	~this()
	{}

	void loadShader(char[] fileName)
	{
		shaders ~= new ShaderProgram();
	}

	ShaderProgram getShader()
	{
		if(shaders.length > 0)
		{
			return shaders[0];
		}
		return null;
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