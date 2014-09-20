import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import ShaderProgram;

class GameObject {
	
	float[3] coords;
	bool visible = false;

    ShaderProgram shaderProgram;

    GLuint vArrayID;
    GLfloat[9] vBufferData = [
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0,
        0.0, 1.0, 0.0,
    ];
    GLuint vBuffer;
    GLuint shaderProgramID;

	this()
	{
		coords[] = 0;
        this.shaderProgram = new ShaderProgram;

        glGenBuffers(1, &vBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glBufferData(GL_ARRAY_BUFFER, vBufferData.sizeof, cast(void*)vBufferData, GL_STATIC_DRAW);
	}
	
	~this()
	{

	}

	void draw()
	{
		writeln("To Implement... For Nathan to do?");
		writeln("Did do good buddy");
        shaderProgram.bind();
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        // attribute 0?, size, type, normalized, stride, array buffer offset
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
        // start from vertex 0, 3 total
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glDisableVertexAttribArray(0);
	}
}
