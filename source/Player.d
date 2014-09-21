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

	byte HP;

	float speed;
	float xpan, ypan;

	float width, length;

	float height;

    GameObject gameObj;

	Camera camera;

	TCPsocket mySocket;

	int sendTimer;

	byte playerID;
	byte team;

	bool active = true;

	this(float x, float y, float z, Camera* camera, byte team) {
		this.width = 1.2f;
		this.length = 1.2f;
		this.height = 3.1f;
        gameObj = new GameObject(-width/2, 0, length/2, width/2, height, -length/2);
        gameObj.visible = false;
        setTeam(team);
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

	void setTeam(byte team){
		this.team = team;
		if (team == 1)
        	gameObj.setRGB(1,0,0.2);
        else if (team == 2)
        	gameObj.setRGB(.2,0,1);
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

