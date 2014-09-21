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

	float speed;
	float xpan, ypan;

	float width, length;

	float height;

    GameObject gameObj;

	Camera camera;

	TCPsocket mySocket;

	int sendTimer;

	this(float x, float y, float z, Camera* camera) {
		this.width = 1f;
		this.length = 1f;
		this.height = 3;
        gameObj = new GameObject(-width/2, 0, length/2, width/2, height, -length/2);
        gameObj.visible = false;
        gameObj.setRGB(1,0,0.2);
		this.camera = *camera;
		this.x = x;
		this.y = y;
		this.z = z;

		sendTimer = 2;

		mySocket = null;

		speed = 0.3f;
		xpan = 1.4f;
		ypan = 1f;

		dy = 0;

		gravity = .02f;
	}

	GameObject getGameObject(){
		return gameObj;
	}

	void jump(){
		dy = .4f;
	}

	void update(){
        gameObj.x = x;
        gameObj.y = y;
        gameObj.z = z;
        gameObj.updateMatrix();
	}
}

