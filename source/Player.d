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

class Player {
	float x, y, z;
	float dx, dy, dz;
	float gravity;
	float height;

    GameObject gameObj;

	Camera camera;

	this(float x, float y, float z, Camera* camera, Renderer renderer) {
        gameObj = new GameObject(-1,-1, 1, 1, 1, -1);
        gameObj.visible = true;
        gameObj.setRGB(1,0,0.2);
        renderer.register(gameObj);
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
        gameObj.x = x;
        gameObj.y = y;
        //gameObj.z = z;
        gameObj.updateMatrix();
	}
}
