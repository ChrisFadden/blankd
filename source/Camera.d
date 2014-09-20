import Matrix;

class Camera {
    Matrix projectionMatrix;
    Matrix viewMatrix;
    float[3] loc = 0;
    this() {
        projectionMatrix = new Matrix;
        projectionMatrix.setPerspectiveMatrix(60.0, 1280.0/720.0, 1.0, 100.0);
        viewMatrix = new Matrix;
    }

    void moveTranslation(float dx, float dy, float dz) {
        loc[0] += dx;
        loc[1] += dy;
        loc[2] += dz;
        viewMatrix.setTranslation(-loc[0], -loc[1], -loc[2]);
    }
    
    void setTranslation(float x, float y, float z) {
        loc[0] = x;
        loc[1] = y;
        loc[2] = z;
        viewMatrix.setTranslation(-x, -y, -z);
    }


    Matrix getVPMatrix() {
        return  projectionMatrix * viewMatrix ;
    }
}
