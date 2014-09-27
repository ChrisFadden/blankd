import std.stdio;
import std.string;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import ResourceManager;
import ShaderProgram;
import Texture;
import Matrix;
import Camera;

class GameObject {
	
	float x;
	float y;
	float z;

    float rx;
    float ry;
    float rz;

    float r;
    float g;
    float b;
    float a;
    Matrix modelMatrix;
    GLfloat[] verts;
    GLfloat[] norms;
    GLfloat[] texCords;
    int[] ind;

	bool visible = true;
    bool solid = false;
    bool hasModel = false;
    bool hasTexture = false;

    ShaderProgram shaderProgram;
    Texture texture;

    GLuint vBuffer;
    GLuint nBuffer;
    GLuint tBuffer;
    GLuint iBuffer;
    GLuint shaderProgramID;

    float leftx, rightx;
    float frontz, backz;
    float topy, bottomy;

	this(float x1, float y1, float z1, float x2, float y2, float z2) {
        this(x1,y1,z1,x2,y2,z2, false, null);
    }
	this(float x1, float y1, float z1, float x2, float y2, float z2, bool hasTexture, Texture texture) {
        leftx = x1;
        rightx = x2;
        frontz = z1;
        backz = z2;
        topy = y2;
        bottomy = y1;
        a = 1;

        this.hasTexture = hasTexture;
        this.texture = texture;

        setVertexBuffer(x1, y1, z1, x2, y2, z2);
        norms = [
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
        texCords = [
            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

            0, 0,
            1, 1,
            0, 1,
            0, 0,
            1, 0,
            1, 1,

        ];
        setup();
    }

    void setVertexBuffer(float x1, float y1, float z1, float x2, float y2, float z2) {
        verts = [
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

    this(float x, float z, float width, float length){
        this(x, z, width, length, false, null); 
    }
    this(float x, float z, float width, float length, bool hasTexture, Texture texture){
        leftx = x;
        rightx = x + width;
        frontz = z;
        backz = z + length;
        topy = 0;
        bottomy = 0;

        this.hasTexture = hasTexture;
        this.texture = texture;
        verts = [
            x, 0, z,
            x + width, 0, z + length,
            x, 0, z + length,
            x, 0, z,
            x + width, 0, z,
            x + width, 0, z + length,
        ];
        norms = [
            0,1,0,
            0,1,0,
            0,1,0,
            0,1,0,
            0,1,0,
            0,1,0,
        ];
        texCords = [
            0,0,
            1,1,
            0,1,
            0,0,
            1,0,
            1,1,
        ];

        setup();
    }

    void setup() {
        //writeln("Beginning constructor ", verts.sizeof);
		x = 0;
		y = 0;
		z = 0;
        rx = 0;
        ry = 0;
        rz = 0;
        r = 0;
        g = 0;
        b = 0;
        modelMatrix = new Matrix();
        updateMatrix();

        this.shaderProgram = getResourceManager().getShader(hasTexture);

        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Pre buffer error!");
        glGenBuffers(1, &vBuffer);
        glGenBuffers(1, &nBuffer);
        glGenBuffers(1, &tBuffer);
        glGenBuffers(1, &iBuffer);
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Post buffer error!");
        updateMesh();
	}

    void updateMesh(){
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glBufferData(GL_ARRAY_BUFFER, verts.length*GLfloat.sizeof, cast(void*)verts, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, nBuffer);

        glBufferData(GL_ARRAY_BUFFER, norms.length*GLfloat.sizeof, cast(void*)norms, GL_STATIC_DRAW);
        if(hasModel)
        {
            //Object has a model thus an index buffer.
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iBuffer);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, int.sizeof*ind.length, &ind[0], GL_STATIC_DRAW);
        }

        if (hasTexture) {
            glBindBuffer(GL_ARRAY_BUFFER, tBuffer);
            glBufferData(GL_ARRAY_BUFFER, texCords.length*GLfloat.sizeof, cast(void*)texCords, GL_STATIC_DRAW);
        }

        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Is buffer error!");
        //writeln("Done buffers, shader");
    }
	
	~this()
	{
	}

    void updateMatrix() {
        //modelMatrix.setIdentity();
        //modelMatrix.rotate(rx,ry,rz);
        //modelMatrix.setTranslation(x, y, z);
        modelMatrix.setTranslation(x, y, z);
        modelMatrix.rotate(rx,ry,rz);
    }

	void draw(Camera camera) {
        // Model matrix
        int error;
        
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Error Before Bind!!");
            writeln(error);
        }
        shaderProgram.bind(modelMatrix, camera.getVPMatrix(), r, g, b, a);
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Error After Bind!");
            writeln(error);
        }

        int mPositionHandle = glGetAttribLocation(shaderProgram.programID, "vertPos_model");   
        int mNormalHandle = glGetAttribLocation(shaderProgram.programID, "norm_model");
        int mTexHandle = 0;
        
        //Object doesn't have a model/vertices are placed
        // attribute, size, type, normalized, stride, array buffer offset
        glBindBuffer(GL_ARRAY_BUFFER, vBuffer);
        glVertexAttribPointer(mPositionHandle, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
        glEnableVertexAttribArray(mPositionHandle);

        glBindBuffer(GL_ARRAY_BUFFER, nBuffer);
        glVertexAttribPointer(mNormalHandle, 3, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
        glEnableVertexAttribArray(mNormalHandle);

        if (hasTexture) {
            while ((error = glGetError()) != GL_NO_ERROR)
                writeln("pre getAttrib Texture error!", error);
            mTexHandle = glGetAttribLocation(shaderProgram.programID, "texCord");
            while ((error = glGetError()) != GL_NO_ERROR)
                writeln("getAttribLocation Texture error!", error);
            glBindBuffer(GL_ARRAY_BUFFER, tBuffer);
            while ((error = glGetError()) != GL_NO_ERROR)
                writeln("glBindBuffer Texture error!", error);
            glVertexAttribPointer(mTexHandle, 2, GL_FLOAT, GL_FALSE, 0, cast(void*)0);
            while ((error = glGetError()) != GL_NO_ERROR) {
                writeln("glVertexAttribPointer Texture error! ", error);
                if (error == GL_INVALID_ENUM)
                    writeln("GL_INVALID_ENUM");
                else if (error == GL_INVALID_VALUE) {
                    int maxAtt;
                    glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &maxAtt);
                    writeln("GL_INVALID_VALUE, mTexHandle: ", mTexHandle, " GL_MAX_VERTEX_ATTRIBS: ", maxAtt);
                }
                else
                    writeln("Not recognized error!");
            }
            glEnableVertexAttribArray(mTexHandle);
            while ((error = glGetError()) != GL_NO_ERROR)
                writeln("getAttrib Texture error!", error);

            glActiveTexture(GL_TEXTURE0);
            GLint loc = glGetUniformLocation(shaderProgram.programID, "texture");
            glBindTexture(GL_TEXTURE_2D, texture.texID);
            glUniform1i(loc, 0); // GL_TEXTURE0 + n

            while ((error = glGetError()) != GL_NO_ERROR)
                writeln("getUniform Texture error!", error);
        }

        if (!hasModel) {
            // start from vertex 0, verts.length/3 total
            glDrawArrays(GL_TRIANGLES, 0, cast(int)verts.length/3);
        } else {
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, iBuffer);
            glDrawElements(GL_TRIANGLES, cast(int)ind.length, GL_UNSIGNED_INT, cast(void *)0);
        }
        glDisableVertexAttribArray(mPositionHandle);
        glDisableVertexAttribArray(mNormalHandle);
        if (hasTexture)
            glDisableVertexAttribArray(mTexHandle);
	}

    void setRGB(float r, float g, float b) {
        writeln("Setting RGBA!!!");
        setRGB(r,g,b,1);
    }

    void setRGB(float r, float g, float b, float a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    void printVerts()
    {
        writeln("verts: ",verts.length);
        for(int i = 0; i < verts.length/3; i++)
        {
            writeln(ind[i]);
            writeln(verts[i*3]," ",verts[i*3+1]," ",verts[i*3+2]);
            writeln(norms[i*3]," ",norms[i*3+1]," ",norms[i*3+2]);
            writeln("");
        }
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
        gameObject.setRGB(.7,.7,.6);
        gameObject.updateMatrix();
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
        gameObject.setRGB(1,1,0.9);
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
        gameObject.setRGB(.7,.7,0.6);
        width = dx;
        length = dz;
        height = dy;
        gameObject.updateMatrix();
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
        } else if (starty > 0f){
            starty -= dy;
        }
        updateMesh();
    }

    void updateMesh() {
        gameObject.setVertexBuffer(startx,starty,startz,startx+width,starty+height,startz-length);
        gameObject.updateMesh();
    }
}
