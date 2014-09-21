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

	float speed;
	float xpan, ypan;

	float width, length;

	float height;

	Camera camera;

	this(float x, float y, float z, Camera* camera){
		this.camera = *camera;
		this.x = x;
		this.y = y;
		this.z = z;

		speed = 0.3f;
		xpan = 1.4f;
		ypan = 1f;

		dy = 0;

		this.width = 1f;
		this.length = 1f;

		gravity = .02f;

		this.height = 3;
	}

	void jump(){
		dy = .4f;
	}

	
}