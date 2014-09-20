import std.stdio;
import std.string;

import derelict.opengl3.gl3;

import Matrix;

class ShaderProgram {
    GLuint programID;
    this() {
        this(simpleVertShaderSource, simpleFragShaderSource);
    }
    this(string vertSrc, string fragSrc) {
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Pre makeShaders error!");
        programID = makeShaders(vertSrc, fragSrc);
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("makeShaders error!");
    }
    void bind(Matrix modelMatrix, Matrix viewProjectionMatrix, float r, float g, float b) {
        glUseProgram(programID);
        //modelMatrix.setIdentity();
        //viewProjectionMatrix.setIdentity();
        glUseProgram(programID);
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Not uniform location error!");
            writeln(error);
        }


        GLint modelMatrixHandle = glGetUniformLocation(programID, "modelMatrix");
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Get uniform location error 1!");

        GLint viewProjectionMatrixHandle = glGetUniformLocation(programID, "viewProjectionMatrix");
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Get uniform location error 2!");

        GLint colorHandle = glGetUniformLocation(programID, "materialColor");
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Get uniform location error 2!");
        

        glUniform3f(colorHandle, r, g, b);
        glUniformMatrix4fv(modelMatrixHandle, 1, GL_FALSE, cast(float*)modelMatrix.matrix);
        glUniformMatrix4fv(viewProjectionMatrixHandle, 1, GL_FALSE, cast(float*)viewProjectionMatrix.matrix);
    }
}

string simpleVertShaderSource = "
#version 120
attribute vec3 vertPos_model;
attribute vec3 vertNorm_model;

uniform mat4 modelMatrix;
uniform mat4 viewProjectionMatrix;

//uniform vec3 materialColor;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;

void main() {
    gl_Position = viewProjectionMatrix * modelMatrix * vec4(vertPos_model, 1);
    position_modelSpace = modelMatrix * vec4(vertPos_model, 1);
    normal_modelSpace = normalize(modelMatrix * vec4(vertNorm_model, 1));
}
";

string simpleFragShaderSource = "
#version 120

uniform vec3 materialColor;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;

void main() {
    vec4 light_pos = vec4(20, 80, 0, 1);
    vec3 light_color = vec3(3000,3000,3000);

    vec3 matDiffuseColor = vec3(0.9, 0.9, 0.9);

    float cosTheta = clamp( dot(normal_modelSpace, light_pos), 0, 1);
    float dist = distance(position_modelSpace, light_pos);  
    //float distance = 0.8;  
    //gl_FragColor =  vec4(cosTheta * light_color, 1);
    gl_FragColor =  vec4(0.3,0.3,0.3,0) + vec4((cosTheta * materialColor * light_color) / (dist * dist), 1);
    //gl_FragColor =  vec4(light_color / (distance * distance), 1);
    //gl_FragColor = vec4(1,0,0,1);
    //gl_FragColor = position_modelSpace;
}
";


GLuint makeShaders(string vertSource, string fragSource) {
    GLuint vertID = glCreateShader(GL_VERTEX_SHADER);
    GLuint fragID = glCreateShader(GL_FRAGMENT_SHADER);
    GLuint progID = glCreateProgram();
    GLint result = GL_FALSE;
    int logLength;

        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Prein makeShaders error!");

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
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Vertex makeShaders error!");

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
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Frag makeShaders error!");

    // linking
    debug writeln("Linking shader program");
    glAttachShader(progID, vertID);
    glAttachShader(progID, fragID);
    glLinkProgram(progID);

    while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Link error!", error);

    //TODO FIX THIS
    /*
    debug {
        glGetProgramiv(progID, GL_LINK_STATUS, &result);
        glGetProgramiv(progID, GL_INFO_LOG_LENGTH, &logLength);
        char[] progLog = new char[logLength];
        glGetShaderInfoLog(progID, logLength, cast(GLsizei*)null, progLog.ptr);
        writeln("Linking program info log: ", progLog);
    }
    */
    glDeleteShader(vertID);
    glDeleteShader(fragID);
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln(" delete error!");

    return progID;
}
