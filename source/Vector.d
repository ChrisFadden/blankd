import std.math;

class Vector {
    float x;
    float y;
    float z;
    this(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    float magnitude() {
        return sqrt(x*x + y*y + z*z);
    }
    Vector opBinary(string op)(Vector rhs) {
        static if (op == "+") { 
           return new Vector(x+rhs.x, y+rhs.y, z+rhs.z);
        } else static if (op == "*") {
           return new Vector(y*rhs.z - rhs.y*z, -(x*rhs.z - rhs.x*z), x*rhs.y - rhs.z*y);
        } else static if (op == "=") {
            x = rhs.x;
            y = rhs.y;
            z = rhs.z;
            return this;
        } else static assert(0, "Operator "~op~" not implemented");
    }
    
    Vector opBinary(string op)(float rhs) {
        static if (op == "/") { 
           return new Vector(x/rhs, y/rhs, z/rhs);
        } else static if (op == "*") {
           return new Vector(x*rhs, y*rhs, z*rhs);
        } else static assert(0, "Operator "~op~" not implemented");
    }
}
