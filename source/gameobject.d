import std.stdio;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import ShaderProgram;
import Matrix;
import Camera;

class GameObject {
	
	float x;
	float y;
	float z;
    Matrix modelMatrix;

	bool visible = false;

    ShaderProgram shaderProgram;

    GLuint vArrayID;
    GLfloat[] vBufferData;
    uint vBufferLen;
    GLuint vBuffer;
    GLuint shaderProgramID;

	this(float x1, float y1, float z1, float x2, float y2, float z2) 
	{
        vBufferLen = 9;
        vBufferData = [
            x1, y1, z1,
            x2, y2, z2,
            0.0, 1.0, 0.0,
        ];
        setup();
    }

	this()
	{
        vBufferLen = 9;
        vBufferData = [
            -1.0, -1.0, 0.0,
            1.0, -1.0, 0.0,
            0.0, 1.0, 0.0,
        ];
        setup();
    }

    void setup() {
        writeln("Beginning constructor", vBufferData.sizeof);
		x = 0;
		y = 0;
		z = 0;
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
        glBufferData(GL_ARRAY_BUFFER, vBufferLen*GLfloat.sizeof, cast(void*)vBufferData, GL_STATIC_DRAW);
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

	void draw(Camera camera)
	{
        // Model matrix
        shaderProgram.bind(modelMatrix, camera.getVPMatrix());       
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        // attribute 0?, size, type, normalized, stride, array buffer offset
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);

        // start from vertex 0, vBufferLen/3 total
        glDrawArrays(GL_TRIANGLES, 0, vBufferLen/3);
        glDisableVertexAttribArray(0);
	}
}
