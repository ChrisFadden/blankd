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
    float horizontalAngle = 3.14;
    float verticalAngle = 0;
    this() {
        projectionMatrix = new Matrix;
        projectionMatrix.setPerspectiveMatrix(60.0, 1280.0/720.0, 1.0, 100.0);
        viewMatrix = new Matrix;
    }

    void resetRotation(){
        horizontalAngle = 3.14;
        verticalAngle = 0;
    }

    //Quat rotatoinBetweenVectors(Vector start, Vector dest) {
        //start = 
    //}
    //void setLookAt(Vector eye, Vector center, Vector up) {
        
    //}
    void setLookAt(Vector eye, Vector center, Vector up) {
        //viewMatrix.setLookAtMatrix(eye, center, up);
        //writeln(viewMatrix.matrix);
        Matrix look = new Matrix();
        //look.setLookAtMatrix(eye.x, eye.y, eye.z,
                    //center.x, center.y, center.z,
                    //up.x, up.y, up.z);
        look.setLookAtMatrix(eye, center, up);
        viewMatrix.setIdentity();
        viewMatrix.translate(-eye.x, -eye.y, -eye.z);
        viewMatrix = look * viewMatrix;
    }
    void setLookAt(float eyeX, float eyeY, float eyeZ,
                        float centerX, float centerY, float centerZ,
                        float upX, float upY, float upZ) {

        viewMatrix.setLookAtMatrix(eyeX, eyeY, eyeZ,
                                    centerX, centerY, centerZ,
                                    upX, upY, upZ);
    }

    void moveTranslation(float dx, float dy, float dz) {
        float scale = 1;
        //writeln("waafa", position.toString());
        position = position +  direction * scale * dz;
        position = position +  right * scale * dx;
        position = position + up * scale * dy;
    }
    
    void setTranslation(float x, float y, float z) {
        position = new Vector(x, y ,z);
    }

    void moveRotation(float dx, float dy) {
        horizontalAngle += dx;
        verticalAngle += dy;
        //if (verticalAngle < -0.3)
            //verticalAngle = -0.3;
        //if (verticalAngle > 0.3)
            //verticalAngle = 0.3;

        direction = new Vector(cos(verticalAngle)*sin(horizontalAngle),
                                sin(verticalAngle),
                                cos(verticalAngle)*cos(horizontalAngle));
        right = new Vector(sin(horizontalAngle - 3.14/2.0),
                                    0,
                                    cos(horizontalAngle - 3.14/2.0));
        up = right * direction;
        //up = new Vector(0,1,0);
    }


    Matrix getVPMatrix() {
        //writeln("baba", position.toString);
        setLookAt(position, position+direction, up);
        //setLookAt(position, position+direction, new Vector(0,1,0));
        return  projectionMatrix * viewMatrix;
    }
}
