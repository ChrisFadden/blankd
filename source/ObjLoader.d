import std.file, std.stdio, std.string;
import gameobject;

class ObjLoader
{
	this()
	{}

	~this()
	{}

	void open(string fname, GameObject g)
	{
		File file = File(fname, "r");

		string[] v;
		v.length = 100;
		string[] f;
		f.length = 100;
		string temp;
		
		int i = 0;
		int j = 0;
		while(!file.eof())
		{
			temp = file.readln();
			if(temp.length != 0 && temp[0] == 'f')
			{
				//load the faces
				f[i] = temp;
				i++;
				//printf("%s",toStringz(temp));
			}
			else if(temp.length != 0 && temp[0] == 'v')
			{
				v[j] = temp;
				j++;
				//printf("%s",toStringz(temp));
			}
		}
		if(v[0] != "")
		{
			g.verts = v;
			g.faces = f;
		}
		//writeln(file);


		file.close();
	}
}