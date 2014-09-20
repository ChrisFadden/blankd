import std.stdio;

class GameObject {
	
	float[3] coords;
	bool visible = false;

	this()
	{
		coords[] = 0;
	}
	
	~this()
	{

	}

	void Draw()
	{
		writeln("To Implement... For Nathan to do?");
	}
}