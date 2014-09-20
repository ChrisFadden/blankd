import Matrix;

class Camera {
    Matrix projectionMatrix;
    Matrix viewMatrix;
    this() {
        projectionMatrix = new Matrix;
        projectionMatrix.setPerspectiveMatrix(90.0, 1280/720, 1.0, 100.0);
        viewMatrix = new Matrix;
    }
    
    void setTranslation(float x, float y, float z) {
        viewMatrix.setTranslation(-x, -y, -z);
    }


    Matrix getVPMatrix() {
        return viewMatrix * projectionMatrix;
    }
}
