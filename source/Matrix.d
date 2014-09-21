import std.math;
import std.stdio;

import Vector;

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

    float[4] opBinary(string op)(float[4] rhs) {
        static if (op == "*") {
           float[4] result = 0;
           for (int j = 0; j < 4; j++) {
                result[j] =  matrix[j] * rhs[0]
                                    + matrix[j+4] * rhs[1]
                                    + matrix[j+8] * rhs[2]
                                    + matrix[j+12] * rhs[3];
           }
           return result;
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

    void translate(float x, float y, float z) {
        Matrix trans = new Matrix();
        trans.setTranslation(x, y, z);
        matrix[] = (trans * this).matrix[];
    }

    struct MatrixTrip {Matrix x; Matrix y; Matrix z;};

    MatrixTrip  rotateTrip(float x, float y, float z) {
        Matrix rotXMat = new Matrix;
        Matrix rotYMat = new Matrix;
        Matrix rotZMat = new Matrix;
        
        // The X rotation matrix
        rotXMat.matrix[] = 0;
        rotXMat.matrix[0] = 1;
        rotXMat.matrix[5] = cos(x);
        rotXMat.matrix[6] = sin(x);
        rotXMat.matrix[9] = -sin(x);
        rotXMat.matrix[10] = cos(x);
        rotXMat.matrix[15] = 1;

        rotYMat.matrix[] = 0;
        rotYMat.matrix[0] = cos(y);
        rotYMat.matrix[2] = -sin(y);
        rotYMat.matrix[5] = 1;
        rotYMat.matrix[8] = sin(y);
        rotYMat.matrix[10] = cos(y);
        rotYMat.matrix[15] = 1;

        rotZMat.matrix[] = 0;
        rotZMat.matrix[0] = cos(z);
        rotZMat.matrix[1] = sin(z);
        rotZMat.matrix[4] = -sin(z);
        rotZMat.matrix[5] = cos(z);
        rotZMat.matrix[10] = 1;
        rotZMat.matrix[15] = 1;

        MatrixTrip ret = {x:rotXMat, y:rotYMat, z:rotZMat};
        return ret;
    }

    void rotate(float x, float y, float z) {
        MatrixTrip forward = rotateTrip(x,y,z);
        matrix[] = (forward.x * forward.y * forward.z * this).matrix[];
    }
    
    Matrix rotateWithReverse(float x, float y, float z) {
        rotate(x,y,z);
        MatrixTrip back = rotateTrip(-x,-y,-z);
        return back.z * back.y * back.z;
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
        float f = 1.0f/tan(degtorad(fovy/2.0f));
        matrix[0] = f/aspect;
        matrix[5] = f;
        matrix[10] = (zFar+zNear)/(zNear-zFar);
        matrix[11] = -1;
        matrix[14] = (2.0*zFar*zNear)/(zNear-zFar);
    }
}
float degtorad(float deg) {
    return (deg % 360.0) /180 * PI;
}

