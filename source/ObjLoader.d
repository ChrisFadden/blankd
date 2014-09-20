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
		string[] f;
		string[] n;
		string temp;
		
		while(!file.eof())
		{
			temp = file.readln();
			if(temp.length != 0 && temp[0] == 'f')
			{
				//load the faces
				f ~= temp;
				//printf("%s",toStringz(temp));
			}
			else if(temp.length != 0 && temp[0] == 'v' && temp[1] != 'n' )
			{
				//load the vertices
				v ~= temp;
				//printf("%s",toStringz(temp));
			}
			else if(temp.length != 0 && temp[0] == 'v' && temp[1] == 'n')
			{
				//load the normals
				n ~= temp;
			}
		}
		
		if(v[0] != "")
		{
			//Write values to given object;
			//g.verts = v;
			int count = 0;
			int t;
			while(v.length > count && v[count] != "")
			{
				string[] splitted = split(v[count]);
				t = 1;
				while(t < splitted.length)
				{
					g.verts ~= to!float(splitted[t]);
					t++;
				}
				count++;
			}

			count = 0;
			while(f.length > count && f[count] != "")
			{
				string[] splitted = split(f[count]);
				t = 1;
				while(t < splitted.length)
				{
					string fnormed = splitted[t];
					ptrdiff_t ind = fnormed.indexOfAny("/");
					string face = fnormed[0..ind];
					ptrdiff_t ind2 = fnormed.lastIndexOf("/");
					string norm = fnormed[ind2+1..$];
					g.faces ~= to!int(face);
					g.faces ~= to!int(norm);
					t++;
				}
				count++;
			}

			count = 0;
			while(n.length > count && n[count] != "")
			{
				string[] splitted = split(n[count]);
				t = 1;
				while(t < splitted.length)
				{
					g.norms ~= to!float(splitted[t]);
					t++;
				}
				count++;
			}
		}
		//writeln(file);


		file.close();
	}
}