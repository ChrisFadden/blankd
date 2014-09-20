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

    void rotate(float x, float y, float z) {
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

        matrix[] = (rotXMat * rotYMat * rotZMat * this).matrix[];
    
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

    //void setPerspectiveMatrix(float fovy, float aspect, float zNear, float zFar) {
        //float tanHalfFovy = tan(degtorad(fovy/2.0f));
        //matrix[0] = 1.0/ (tanHalfFovy*aspect);
        //matrix[5] = 1.0/tanHalfFovy;
        //matrix[10] = - (zFar+zNear)/(zNear-zFar);
        //matrix[11] = -1;
        //matrix[14] = -(2.0*zFar*zNear)/(zNear-zFar);
    //}

    void setPerspectiveMatrix(float fovy, float aspect, float zNear, float zFar) {
        float f = 1.0f/tan(degtorad(fovy/2.0f));
        writeln("F: ", f);
        matrix[0] = f/aspect;
        matrix[5] = f;
        matrix[10] = (zFar+zNear)/(zNear-zFar);
        matrix[11] = -1;
        matrix[14] = (2.0*zFar*zNear)/(zNear-zFar);
    }

    void setLookAtMatrix(float eyeX, float eyeY, float eyeZ,
                        float centerX, float centerY, float centerZ,
                        float upX, float upY, float upZ) {

        Vector f = new Vector(centerX-eyeX, centerY-eyeY, centerZ-eyeZ);
        f = f/f.magnitude();
        Vector UP = new Vector(upX, upY, upZ);
        UP = UP/UP.magnitude();
        Vector s = f*UP;
        Vector u = (s/s.magnitude()) * f;
        
        matrix[0] = s.x;
        matrix[1] = u.x;
        matrix[2] = -f.x;
        matrix[3] = 0;

        matrix[4] = s.y;
        matrix[5] = u.y;
        matrix[6] = -f.y;
        matrix[7] = 0;

        matrix[8] = s.z;
        matrix[9] = u.z;
        matrix[10] = -f.z;
        matrix[11] = 0;

        matrix[12] = 0;
        matrix[13] = 0;
        matrix[14] = 0;
        matrix[15] = 1;
    }
}

float degtorad(float deg) {
    return (deg % 360.0) /180 * PI;
}

