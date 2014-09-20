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

    float r;
    float g;
    float b;
    Matrix modelMatrix;
    float[] verts;
    int[] faces;
    float[] norms;

	bool visible = false;

    ShaderProgram shaderProgram;

    GLuint vArrayID;
    GLuint nArrayID;
    GLfloat[] vBufferData;
    GLfloat[] nBufferData;
    uint bufferLen;
    GLuint vBuffer;
    GLuint nBuffer;
    GLuint shaderProgramID;

	this(float x1, float y1, float z1, float x2, float y2, float z2) {
        bufferLen = 6*3*6;
        setVertexBuffer(x1, y1, z1, x2, y2, z2);
        nBufferData = [
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,

            0, 1, 0,
            0, 1, 0,
            0, 1, 0,
            0, 1, 0,
            0, 1, 0,
            0, 1, 0,

            0, 0, -1,
            0, 0, -1,
            0, 0, -1,
            0, 0, -1,
            0, 0, -1,
            0, 0, -1,

            0, -1, 0,
            0, -1, 0,
            0, -1, 0,
            0, -1, 0,
            0, -1, 0,
            0, -1, 0,

            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,

            1, 0, 0,
            1, 0, 0,
            1, 0, 0,
            1, 0, 0,
            1, 0, 0,
            1, 0, 0,
        ];
        
        setup();
    }

    void setVertexBuffer(float x1, float y1, float z1, float x2, float y2, float z2) {
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
    }

	this()
	{
        debug writeln("THIS CODE SHOULD NEVER BE RUNNING");
        
        bufferLen = 9;
        vBufferData = [
            -1.0, -1.0, 0.0,
            1.0, -1.0, 0.0,
            0.0, 1.0, 0.0,
        ];
        nBufferData = [
            0.0, 0.0, 1.0,
            0.0, 0.0, 1.0,
            0.0, 0.0, 1.0,
        ];
        
        setup();
    }

    void setup() {
        writeln("Beginning constructor ", vBufferData.sizeof);
		x = 0;
		y = 0;
		z = 0;
        r = 0;
        g = 0;
        b = 0;
        verts.length = 24;
        faces.length = 24;
        modelMatrix = new Matrix();
        updateMatrix();
        writeln("Done matrix");

        this.shaderProgram = new ShaderProgram();
        writeln("Done ShaderProgram");

        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Pre buffer error!");
        glGenBuffers(1, &vBuffer);
        glGenBuffers(1, &nBuffer);
        updateMesh();
	}

    void updateMesh(){
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glBufferData(GL_ARRAY_BUFFER, bufferLen*GLfloat.sizeof, cast(void*)vBufferData, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, nBuffer);
        glBufferData(GL_ARRAY_BUFFER, bufferLen*GLfloat.sizeof, cast(void*)nBufferData, GL_STATIC_DRAW);
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Is buffer error!");
        //writeln("Done buffers, shader");
    }
	
	~this()
	{
	}

    void updateMatrix() {
        modelMatrix.setTranslation(x, y, z);
    }

	void draw(Camera camera) {
        // Model matrix
        int error;
        
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Error Before Bind!!");
            writeln(error);
        }
        shaderProgram.bind(modelMatrix, camera.getVPMatrix(), r, g, b);
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Error After Bind!");
            writeln(error);
        }

        int mPositionHandle = glGetAttribLocation(shaderProgram.programID, "vertPos_model");   
        int mNormalHandle = glGetAttribLocation(shaderProgram.programID, "vertNorm_model");
        
        // attribute 0?, size, type, normalized, stride, array buffer offset
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glVertexAttribPointer(mPositionHandle, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
        glEnableVertexAttribArray(mPositionHandle);
        
        glBindBuffer(GL_ARRAY_BUFFER, nBuffer);
        glVertexAttribPointer(mNormalHandle, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
        glEnableVertexAttribArray(mNormalHandle);

        // start from vertex 0, bufferLen/3 total
        glDrawArrays(GL_TRIANGLES, 0, bufferLen/3);
        glDisableVertexAttribArray(mPositionHandle);
        glDisableVertexAttribArray(mNormalHandle);
	}

    void setRGB(float r, float g, float b) {
        this.r = r;
        this.g = g;
        this.b = b;
    }

    void printVerts()
    {
        writeln(verts);
        writeln(faces);
    }
}

class BlockBuilder {
    float startx, starty, startz;
    float dx = 2.0;
    float dy = 1.0;
    float dz = 2.0;
    float width;
    float length;
    float height;

    bool placing;

    GameObject gameObject;

    this(float startx, float starty, float startz) {
        gameObject = new GameObject(startx,starty,startz,startx+dx,starty+dy,startz-dz);
        this.startx = startx;
        this.starty = starty;
        this.startz = startz;
        width = dx;
        length = dz;
        height = dy;
        placing = false;
    }

    void beginPlace() {
        placing = true;
    }

    float[6] place() {
        float[6] output = [startx, starty, startz, startx+width, starty+height, startz-length];
        placing = false;
        startx = startx+width;
        reset();
        return output;
    }

    GameObject getGameObject() {
        return gameObject;
    }

    void reset() {
        width = dx;
        length = dz;
        height = dy;
        updateMesh();
    }

    void quit() {
        placing = false;
        reset();
    }

    void right() {
        if (placing)
            width += dx;
        else
            startx += dx;
        updateMesh();
    }

    void left() {
        if (placing){
            if (width > dx)
                width -= dx;
            else
                startx -= dx;
        } else {
            startx -= dx;
        }
        updateMesh();
    }

    void up() {
        if (placing)
            length += dz;
        else
            startz -= dz;
        updateMesh();
    }

    void down() {
        if (placing) {
            if (length > dz)
                length -= dz;
            else
                startz += dz;
        } else {
            startz += dz;
        }
        updateMesh();
    }

    void raise() {
        if (placing)
            height += dy;
        else
            starty += dy;
        updateMesh();
    }

    void lower() {
        if (placing) {
            if (height > dy)
                height -= dy;
        } else {
            starty -= dy;
        }
        updateMesh();
    }

    void updateMesh() {
        gameObject.setVertexBuffer(startx,starty,startz,startx+width,starty+height,startz-length);
        gameObject.updateMesh();
    }
}
