import std.file, std.stdio, std.string, std.conv;
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
		v.length = 10;
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
			//Write values to given object;
			//g.verts = v;
			int count = 0;
			while(v[count] != "" && v.length > count)
			{
				string[] splitted = split(v[count]);
				g.verts[0+count*3] = to!float(splitted[1]);
				g.verts[1+count*3] = to!float(splitted[2]);
				g.verts[2+count*3] = to!float(splitted[3]);
				count++;
			}

			count = 0;
			int s = 0;
			int t = 0;
			while(f[count] != "" && f.length > count)
			{
				string[] splitted = split(f[count]);
				t = 1;
				while(t < splitted.length)
				{
					g.faces[s] = to!int(splitted[t]);
					s++;
					t++;
				}
				count++;
			}
		}
		//writeln(file);


		file.close();
	}
}