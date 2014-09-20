import std.stdio;
import std.string;

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
    float[] verts;
    int[] faces;

	bool visible = false;

    ShaderProgram shaderProgram;

    GLuint vArrayID;
    GLfloat[] vBufferData;
    uint vBufferLen;
    GLuint vBuffer;
    GLuint shaderProgramID;

	this(float x1, float y1, float z1, float x2, float y2, float z2) 
	{
        vBufferLen = 48;
        vBufferData = [
            // Front face
            x1, y1, z1,
            x2, y2, z1,
            x1, y2, z1,
            x1, y1, z1,
            x2, y1, z1,
            x2, y2, z1,

            // Top face
            x1, y2, z1,
            x2, y2, z2,
            x1, y2, z2,
            x1, y2, z1,
            x2, y2, z1,
            x2, y2, z2,

            // Back face
            x2, y1, z2,
            x1, y2, z2,
            x2, y2, z2,
            x2, y1, z2,
            x1, y1, z2,
            x1, y2, z2,

            // Bottom face
            x1, y1, z2,
            x2, y1, z1,
            x1, y1, z1,
            x1, y1, z2,
            x2, y1, z2,
            x2, y1, z1,

            // Left face
            x1, y1, z2,
            x1, y2, z1,
            x1, y2, z2,
            x1, y1, z2,
            x1, y1, z1,
            x1, y2, z1,

            // Right face
            x2, y1, z1,
            x2, y2, z2,
            x2, y2, z1,
            x2, y1, z1,
            x2, y1, z2,
            x2, y2, z2,
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

    void printVerts()
    {
        writeln(verts);
        writeln(faces);
    }
}
