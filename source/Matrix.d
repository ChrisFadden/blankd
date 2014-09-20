import std.math;

class Matrix {
    float matrix[16];
    this() {
        setIdentity();
    }

    Matrix opBinary(string op)(Matrix rhs) {
        static if (op == "+") { 
           Matrix result = new Matrix();
           result.matrix[] = matrix[] + rhs.matrix[];
           return result;
        } else static if (op == "*") {
           Matrix result = new Matrix();
           for (int j = 0; j < 4; j++) {
                for (int i = 0; i < 16; i+=4) {
                    result.matrix[j+i] =    matrix[j] * rhs.matrix[i]
                                          + matrix[j+4] * rhs.matrix[i+1]
                                          + matrix[j+8] * rhs.matrix[i+2]
                                          + matrix[j+12] * rhs.matrix[i+3];
                }
           }
           return result;
        } else static if (op == "=") {
            matrix[] = rhs.matrix[];
            return this;
        } else static assert(0, "Operator "~op~" not implemented");
    }

    void setTranslation(float x, float y, float z) {
        matrix[12] = x;
        matrix[13] = y;
        matrix[14] = z;
    }

    void setScale(float x, float y, float z) {
        matrix[0] = x;
        matrix[5] = y;
        matrix[10] = z;
    }

    void setRotation(float x, float y, float z) {
    
    }

    void setIdentity() {
        matrix[] = 0;
        matrix[0] = 1;
        matrix[5] = 1;
        matrix[10] = 1;
        matrix[15] = 1;
    }

    void setOrthographicMatrix(float left, float right, float bottom,float top, float near, float far) {
        matrix[0] = 2.0/(right-left);
        matrix[5] = 2.0/(top-bottom);
        matrix[10] = -2.0/(far-near);
        matrix[0] = 1;

        // t_x, t_y, t_z
        matrix[12] = -(right+left)/(right-left);
        matrix[13] = -(top+bottom)/(top-bottom);
        matrix[12] = -(far+near)/(far-near);

    }

    void setPerspectiveMatrix(float fovy, float aspect, float zNear, float zFar) {
        float f = 1/tan(degtorad(fovy/2));
        matrix[0] = f/aspect;
        matrix[5] = f;
        matrix[10] = (zFar+zNear)/(zNear-zFar);
        matrix[11] = -1;
        matrix[14] = (2*zFar*zNear)/(zNear-zFar);
    }
}

float degtorad(float deg) {
    return (deg % 360.0) /180 * PI;
}

