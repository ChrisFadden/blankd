import std.math;
import std.stdio;

class Vector {
    float x;
    float y;
    float z;
    this(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    string toString() {
        writeln("Vector(",x,",",y,",",z,")");
        return "Vector("~x.stringof~","~y.stringof~","~z.stringof~")";
    }

    float magnitude() {
        //writeln(x,y,z);
        //writeln(x*x+y*y+z*z);
        return sqrt(x*x + y*y + z*z);
    }
    
    Vector normalize() {
        return this / magnitude;
    }

    Vector opBinary(string op)(Vector rhs) {
        static if (op == "+") { 
           return new Vector(x+rhs.x, y+rhs.y, z+rhs.z);
        } else static if (op == "-") {
           return new Vector(x-rhs.x, y-rhs.y, z-rhs.z);
        } else static if (op == "*") {
           return new Vector(y*rhs.z - rhs.y*z, -(x*rhs.z - rhs.x*z), x*rhs.y - rhs.z*y);
        } else static if (op == "=") {
            x = rhs.x;
            y = rhs.y;
            z = rhs.z;
            return this;
        } else static assert(0, "Operator "~op~" not implemented");
    }

    float Dot(Vector rhs) {
        return x*rhs.x + y*rhs.y + z*rhs.z;
    }
    
    Vector opBinary(string op)(float rhs) {
        static if (op == "/") { 
           return new Vector(x/rhs, y/rhs, z/rhs);
        } else static if (op == "*") {
           return new Vector(x*rhs, y*rhs, z*rhs);
        } else static assert(0, "Operator "~op~" not implemented");
    }
}
