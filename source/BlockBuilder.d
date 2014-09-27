import std.stdio;

import gameobject;


class BlockBuilder {

    float startx, starty, startz;
    static float dx = 2.0;
    static float dy = 1.0;
    static float dz = 2.0;
    float width;
    float length;
    float height;

    float dir;

    bool placing;

    byte team;

    GameObject gameObject;

    this(float startx, float starty, float startz) {
        gameObject = new GameObject(startx,starty,startz,startx+dx,starty+dy,startz-dz);
        gameObject.setColor(.7,.7,.6);
        gameObject.updateMatrix();
        this.startx = startx;
        this.starty = starty;
        this.startz = startz;
        width = dx;
        length = dz;
        height = dy;
        placing = false;
        team = 0;

        dir = 0;
    }

    void beginPlace() {
        placing = true;
        gameObject.setColor(1,1,0.9);
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
        gameObject.setColor(.7,.7,0.6);
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
        if (placing){
        	if (team != 1 || startx+width < 0)
            	width += dx;
        }
        else{
        	if (team != 1 || startx+dx < 0)
            	startx += dx;
        }
        updateMesh();
    }

    void left() {
        if (placing){
            if (width > dx)
                width -= dx;
            else if (team != 2 || startx > 0)
                startx -= dx;
        } else if (team != 2 || startx > 0){
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

