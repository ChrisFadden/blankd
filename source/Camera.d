import std.math;
import std.stdio;

import Matrix;

class Camera {
    Matrix projectionMatrix;
    Matrix viewMatrix;
    Vector position;
    Vector direction;
    Vector right;
    Vector up;
    float horizontalAngle = 0;
    float verticalAngle = 0;
    this() {
        projectionMatrix = new Matrix;
        projectionMatrix.setPerspectiveMatrix(60.0, 1280.0/720.0, 1.0, 100.0);
        viewMatrix = new Matrix;
        position = new Vector(0,0,0);
    }

    void resetRotation(){
        horizontalAngle = 0;
        verticalAngle = 0;
    }

    void moveTranslation(float dx, float dy, float dz) {
        float scale = 1;
        //writeln("waafa", position.toString());
        position = position +  direction * scale * -dz;
        position = position +  right * scale * -dx;
        position = position + up * scale * dy;
    }
    
    void setTranslation(float x, float y, float z) {
        position = new Vector(x, y ,z);
    }

    void moveRotation(float dx, float dy) {
        horizontalAngle += dx;
        verticalAngle += dy;
        if (verticalAngle > PI/2)
            verticalAngle = PI/2;
        else if (verticalAngle < -PI/2)
            verticalAngle = -PI/2;

        direction = new Vector(cos(verticalAngle)*sin(horizontalAngle),
                                sin(verticalAngle),
                                cos(verticalAngle)*cos(horizontalAngle));
        right = new Vector(sin(horizontalAngle - 3.14/2.0),
                                    0,
                                    cos(horizontalAngle - 3.14/2.0));
        up = right * direction;
    }


    Matrix getVPMatrix() {
        viewMatrix.setIdentity();
        viewMatrix.translate(-position.x, -position.y, -position.z);
        viewMatrix.rotate(-verticalAngle, -horizontalAngle, 0);
        return  projectionMatrix * viewMatrix;
    }
}
