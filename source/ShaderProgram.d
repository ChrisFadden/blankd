import std.stdio;
import std.string;

import derelict.opengl3.gl3;

class ShaderProgram {
    GLuint progamID;
    this() {
        this(simpleVertShaderSource, simpleFragShaderSource);
    }
    this(string vertSrc, string fragSrc) {
        progamID = makeShaders(vertSrc, fragSrc);
    }
    void bind() {
        glUseProgram(progamID); 
    }
}

string simpleVertShaderSource = "
#version 120
attribute vec3 vertPos_model;

void main() {
    gl_Position.xyz = vertPos_model;
    gl_Position.w = 1.0;
}
";

string simpleFragShaderSource = "
#version 120

void main() {
    gl_FragColor = vec4(1,0,0,0);
}
";


GLuint makeShaders(string vertSource, string fragSource) {
    GLuint vertID = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragID = glCreateShader(GL_FRAGMENT_SHADER);
    GLuint progID = glCreateProgram();
    GLint result = GL_FALSE;
    int logLength;

    // Compile the vertex shader
    debug writeln("Compiling vertex shader");
    const GLchar* vertCStr = vertSource.toStringz();
    glShaderSource(vertID, 1, &vertCStr, cast(GLint*)null);
    glCompileShader(vertID);

    debug {
        glGetShaderiv(vertID, GL_COMPILE_STATUS, &result);
        glGetShaderiv(vertID, GL_INFO_LOG_LENGTH, &logLength);
        char[] vertLog = new char[logLength];
        glGetShaderInfoLog(vertID, logLength, cast(GLsizei*)null, vertLog.ptr);
        debug writeln("Vertex shader compilation info log: ", vertLog);
    }

    // Compile the fragment shader
    debug writeln("Compiling fragment shader");
    const GLchar* fragCStr = fragSource.toStringz();
    glShaderSource(fragID, 1, &fragCStr, cast(GLint*)null);
    glCompileShader(fragID);

    debug {
        glGetShaderiv(fragID, GL_COMPILE_STATUS, &result);
        glGetShaderiv(fragID, GL_INFO_LOG_LENGTH, &logLength);
        char[] fragLog = new char[logLength];
        glGetShaderInfoLog(fragID, logLength, cast(GLsizei*)null, fragLog.ptr);
        debug writeln("Fragment shader compilation info log: ", fragLog);
    }

    // linking
    debug writeln("Linking shader program");
    glAttachShader(progID, vertID);
    glAttachShader(progID, fragID);
    glLinkProgram(progID);

    debug {
        glGetProgramiv(progID, GL_LINK_STATUS, &result);
        glGetProgramiv(progID, GL_INFO_LOG_LENGTH, &logLength);
        char[] progLog = new char[logLength];
        glGetShaderInfoLog(progID, logLength, cast(GLsizei*)null, progLog.ptr);
        writeln("Linking program info log: ", progLog);
    }
    glDeleteShader(vertID);
    glDeleteShader(fragID);

    return progID;
}
