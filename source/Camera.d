import Matrix;

class Camera {
    Matrix projectionMatrix;
    Matrix viewMatrix;
    this() {
        projectionMatrix = new Matrix;
        projectionMatrix.setPerspectiveMatrix(60.0, 1280.0/720.0, 1.0, 100.0);
        viewMatrix = new Matrix;
    }

    void setLookAt(float eyeX, float eyeY, float eyeZ,
                        float centerX, float centerY, float centerZ,
                        float upX, float upY, float upZ) {

        viewMatrix.setLookAtMatrix(eyeX, eyeY, eyeZ,
                                    centerX, centerY, centerZ,
                                    upX, upY, upZ);
    }

    void moveTranslation(float dx, float dy, float dz) {
        viewMatrix.translate(-dx,-dy,-dz);
    }
    
    void setTranslation(float x, float y, float z) {
        viewMatrix.setIdentity();
        viewMatrix.translate(-x,-y,-z);
    }

    void moveRotation(float x, float y, float z) {
        viewMatrix.rotate(-x, -y, -z); 
    }


    Matrix getVPMatrix() {
        return  projectionMatrix * viewMatrix ;
    }
}
