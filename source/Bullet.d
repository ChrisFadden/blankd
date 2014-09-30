import Player;
import Vector;
import gameobject;

class Bullet{
	
	Vector position;
	Vector direction;
	float speed;
	float time;

	Player source;

	GameObject gameObject;

	this(){
		gameObject = new GameObject(-.1f,-.1f,.1f,.1f,.1f,-.1f);
		gameObject.setColor(1,1,1);
		gameObject.visible = false;
		this.position = new Vector(0,0,0);
		this.direction = new Vector(0,0,0);
		this.speed = 10;
		this.time = 10;
	}

	void set(Vector position, Vector direction, float speed){
		gameObject.visible = true;
		this.position = position;
		this.direction = direction;
		this.speed = speed;
		gameObject.setPosition(position);
		time = 15;
	}

	void update(){
		time--;
		gameObject.setPosition(position);
	}

	GameObject getGameObject(){
		return gameObject;
	}

	void kill(){
		gameObject.visible = false;
	}

	bool isDead(){
		return time <= 0;
	}

}