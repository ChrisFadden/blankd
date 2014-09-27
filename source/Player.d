import std.stdio;
import core.thread;
import std.string;
import std.math;

import gameobject;
import std.conv;
import ObjLoader;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

class Player {
	float x, y, z;
	float oldx, oldy, oldz;
	float dx, dy, dz;
	float gravity;

	float startx, starty, startz;

	byte hp;

	float speed;
	float xpan, ypan;

	float scanx, scanz;

	float lrAmnt, fbAmnt;
	float oldlrAmnt, oldfbAmnt;

	float width, length;

	float height;
	float eyeHeight;

    GameObject gameObj;

	Camera camera;

	TCPsocket mySocket;

	int sendTimer;
	int respawnTimer;
	bool alive;

	byte playerID;
	byte team;

	bool active = true;
	bool removed = false;

	this(float x, float y, float z, Camera* camera, byte team) {
		this.width = 1.2f;
		this.length = 1.2f;
		this.height = 3.1f;
		this.eyeHeight = 3.0f;
        gameObj = new GameObject(-width/2, 0, length/2, width/2, height, -length/2);
        gameObj.visible = false;
        setTeam(team);
		this.camera = *camera;
		this.x = x;
		this.y = y;
		this.z = z;
		oldx = this.x;
		oldy = this.y;
		oldz = this.z;

		scanx = 0;
		scanz = 0;
		oldlrAmnt = lrAmnt = 0;
		oldfbAmnt = fbAmnt = 0;

		hp = 4;

		sendTimer = 4;


		respawnTimer = 0;
		alive = true;

		mySocket = null;

		speed = 0.3f;
		xpan = 1.4f;
		ypan = 1f;

		dx = 0;
		dy = 0;
		dz = 0;

		gravity = .02f;
	}

	void setOld(){
		oldx = x;
		oldy = y;
		oldz = z;
	}

	void spawn(){
		gameObj.visible = true;
		alive = true;
		x = startx;
		y = starty;
		z = startz;
		camera.setTranslation(x,y+height,z);
		camera.resetRotation();
		if (team == 1)
			camera.moveRotation(-PI/2, 0);
		else
			camera.moveRotation(PI/2, 0);
		hp = 4;
		update();
	}

	void die(){
		alive = false;
		gameObj.visible = false;
		// Five second respawn
		respawnTimer = (60) * 5;
	}

	bool isAlive(){
		return alive;
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

class Flag {
	byte team;
	byte playerCarrying;

	GameObject gameObject;

	float lockx, locky, lockz;

	this(byte team){
		this.team = team;
		gameObject = new GameObject(0,0,0,0);
		playerCarrying = -1;
		setColor();
	}

	void lock() {
		this.lockx = gameObject.x;
		this.locky = gameObject.y;
		this.lockz = gameObject.z;
	}

	bool isHome(){
		return (gameObject.x == lockx && gameObject.y == locky && gameObject.z == lockz);
	}

	void reset(){
		playerCarrying = -1;
		gameObject.x = lockx;
		gameObject.y = locky;
		gameObject.z = lockz;
		gameObject.updateMatrix();
	}

	GameObject getGameObject(){
		return gameObject;
	}

	void setColor(){
		if (team == 1) {
			gameObject.setRGB(1,.4,.4);
		} else if (team == 2) {
			gameObject.setRGB(.4,.4,1);
		}
	}
}

