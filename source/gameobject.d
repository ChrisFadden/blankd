import std.stdio;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import ShaderProgram;
import Matrix;

class GameObject {
	
	float x;
	float y;
	float z;
    Matrix modelMatrix;
    float[] verts;
    int[] faces;

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
        writeln("Beginning constructor");
		x = 0;
		y = 0;
		z = 0;
        verts.length = 24;
        faces.length = 24;
        modelMatrix = new Matrix();
        updateMatrix();
        writeln("Done matrix");

        this.shaderProgram = new ShaderProgram;
        writeln("Done ShaderProgram");

        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Pre buffer error!");

        glGenBuffers(1, &vBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glBufferData(GL_ARRAY_BUFFER, vBufferData.sizeof, cast(void*)vBufferData, GL_STATIC_DRAW);
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Is buffer error!");
        writeln("Done buffers, shader");
	}
	
	~this()
	{
	}

    void updateMatrix() {
        modelMatrix.setTranslation(x, y, z);
    }

	void draw()
	{
        // Model matrix
        shaderProgram.bind(modelMatrix, new Matrix);       
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        // attribute 0?, size, type, normalized, stride, array buffer offset
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);

        // start from vertex 0, 3 total
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glDisableVertexAttribArray(0);
	}

    void printVerts()
    {
        writeln(verts);
        writeln(faces);
    }
}
