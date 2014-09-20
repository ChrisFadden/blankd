import std.stdio;
import core.thread;
import std.string;
import std.math;

import Window;
import Renderer;
import gameobject;
import std.conv;
import ObjLoader;

import networking;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

class Player{
	float x, y, z;
	float dx, dy, dz;
	float gravity;

	float height;

	Camera camera;

	this(float x, float y, float z, Camera* camera){
		this.camera = *camera;
		this.x = x;
		this.y = y;
		this.z = z;

		this.height = 3;
	}

	void move(float dx, float dz){
		this.dx = dx;
		this.dz = dz;
		x += dx;
		z += dz;
	}
}