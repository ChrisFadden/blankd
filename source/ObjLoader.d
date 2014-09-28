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

		//String representation of verts, normals, texture coords, and face indices.
		string[] v;
		string[] f;
		string[] n;
		string[] tc;
		string temp;

		//Hold the data read in from the .obj file
		float[] verts;
		float[] normals;
		float[] texs;
		int[] find;
		int[] tind;
		int[] nind;
		
		writeln("Starting to read file");
		while(!file.eof())
		{
			temp = file.readln();
			if(temp.length != 0 && temp[0] == 'f')
			{
				//load the faces
				f ~= temp;
				//printf("%s",toStringz(temp));
			}
			else if(temp.length != 0 && temp[0] == 'v' && temp[1] != 't' && temp[1] != 'n')
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
			else if(temp.length != 0 && temp[0] == 'v' && temp[1] == 't') {
				tc ~= temp;
			}
		}

		//writeln(verts);
		writeln("Beginning to parse string!!!");
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
				//writeln(splitted);
				while(t < splitted.length)
				{
					//writeln(splitted[t]);
					verts ~= to!float(splitted[t]);
					t++;
				}
				//writeln(verts);
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
					string tex = fnormed[ind+1..ind2];

					find ~= to!int(face);
					nind ~= to!int(norm);
					if(tex.length > 0)
						tind ~= to!int(tex);
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
					normals ~= to!float(splitted[t]);
					t++;
				}
				count++;
			}

			count = 0;
			while(tc.length > count && tc[count] != ""){
				string[] splitted = split(tc[count]);
				t = 1;
				while(t < splitted.length) {
					texs ~= to!float(splitted[t]);
					t++;
				}
				count++;
			}

			int len = 0;
			int oglIndex = 0;
			int normalIndex;
			int faceIndex;
			int texcIndex;
			float[3] tempVert;
			float[3] tempNorm;
			float[3] temp2Vert;
			float[3] temp2Norm;
			float[2] tempTexc;
			float[2] temp2Texc;
			writeln("Writing obj!!!");
			while(len < find.length)
			{
				/*
				** Get Indices
				*/
				normalIndex = nind[len];
				faceIndex = find[len];
				if(tind.length != 0) {
					texcIndex = tind[len];
				}

				/*
				** Get verts/norms/tex coords at those indices
				*/
				tempVert[0] = verts[faceIndex*3-3];
				tempVert[1] = verts[faceIndex*3-2];
				tempVert[2] = verts[faceIndex*3-1];
				tempNorm[0] = normals[normalIndex*3-3];
				tempNorm[1] = normals[normalIndex*3-2];
				tempNorm[2] = normals[normalIndex*3-1];
				if(tind.length != 0) {
					tempTexc[0] = texs[texcIndex*2-2];
					tempTexc[1] = texs[texcIndex*2-1];
				}
				
				
				bool added = false;
				bool hasTcoords = (tind.length != 0);
				for(int j = 0; j < g.ind.length; j++)
				{
					temp2Vert[0..2] = g.verts[(g.ind[j]+1)*3-3..(g.ind[j]+1)*3-1];
					temp2Norm[0..2] = g.norms[(g.ind[j]+1)*3-3..(g.ind[j]+1)*3-1];
					if(hasTcoords) {
						temp2Texc[0..1] = g.texCords[(g.ind[j]+1)*2-2..(g.ind[j]+1)*2-1];
					}
					if(temp2Vert[0] == tempVert[0] && temp2Vert[1] == tempVert[1] && temp2Vert[2] == tempVert[2])
					{
						writeln("temp2Vert: ",temp2Vert);
						writeln("tempVert:  ",tempVert);
						writeln("equal");
						if(temp2Norm[0] == tempNorm[0] && temp2Norm[1] == tempNorm[1] && temp2Norm[2] == tempNorm[2])
						{
							writeln("temp2Norm: ",temp2Norm);
							writeln("tempNorm:  ",tempNorm);
							writeln("equal");
							
							
							if(hasTcoords) {
								//Model has texture coordinates
								if(temp2Texc[0] == tempTexc[0] && temp2Texc[1] == tempTexc[1]) {
									//repeated combination, just add index to end of array.
									g.ind ~= g.ind[j];
									added = true;
									break;
								}
							}
							else {
								//Arrays are equal so just add the repeated index to the end of the array.
								g.ind ~= g.ind[j];
								added = true;
								break;
							}
						}
					}
				}

				if(!added)
				{
					g.verts ~= tempVert;
					g.norms ~= tempNorm;
					if(hasTcoords) {
						g.texCords ~= tempTexc;
					}
					g.ind ~= oglIndex;
					oglIndex++;
				}

				len++;
			}
			g.hasModel = true;
		}
		writeln("Done!!!! Object is indexed!!!");
        // Setup the object
        g.setup();
		file.close();
	}
}
