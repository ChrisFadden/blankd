import std.stdio;
import std.string;

import derelict.opengl3.gl3;

import Matrix;

class ShaderProgram {
    GLuint programID;
    bool hasTexture;
    string type;
    this(bool hasTexture) {
        this.hasTexture = hasTexture;
        if (!hasTexture)
            this(simpleVertShaderSource, simpleFragShaderSource);
        else
            this(texVertShaderSource, texFragShaderSource);
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
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("Before use program error");
            writeln(error);
        }
        glUseProgram(programID);
        while ((error = glGetError()) != GL_NO_ERROR)
        {
            writeln("glUseProgram error!");
            writeln(error);
            writeln("program: ", programID);
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
attribute vec3 norm_model;

uniform mat4 modelMatrix;
uniform mat4 viewProjectionMatrix;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;

void main() {
    gl_Position = viewProjectionMatrix * modelMatrix * vec4(vertPos_model, 1);
    position_modelSpace = modelMatrix * vec4(vertPos_model, 1);
    normal_modelSpace = normalize(modelMatrix * vec4(norm_model, 1));
}
";

string simpleFragShaderSource = "
#version 120

uniform vec3 materialColor;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;

void main() {
    vec4 light_pos = vec4(0, 40, 0, 1);
    vec3 light_color = vec3(30,30,30);

    vec3 matDiffuseColor = vec3(0.9, 0.9, 0.9);

    float cosTheta = clamp( dot(normal_modelSpace, light_pos), 0, 1);
    float dist = distance(position_modelSpace, light_pos); 
    gl_FragColor =   vec4(materialColor * vec3(0.3,0.3,0.3) + (cosTheta * materialColor * light_color) / (dist), 1);
}
";

string texVertShaderSource = "
#version 120
attribute vec3 vertPos_model;
attribute vec3 norm_model;
attribute vec2 texCord;

uniform mat4 modelMatrix;
uniform mat4 viewProjectionMatrix;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;
varying vec2 vTexCord;

void main() {
    gl_Position = viewProjectionMatrix * modelMatrix * vec4(vertPos_model, 1);
    position_modelSpace = modelMatrix * vec4(vertPos_model, 1);
    normal_modelSpace = normalize(modelMatrix * vec4(norm_model, 1));
    vTexCord = texCord;
}
";

string texFragShaderSource = "
#version 120

uniform vec3 materialColor;
uniform sampler2D texture;

varying vec4 position_modelSpace;
varying vec4 normal_modelSpace;
varying vec2 vTexCord;

void main() {
    vec4 light_pos = vec4(0, 40, 0, 1);
    vec4 light_color = vec4(30,30,30, 1);

    vec4 matDiffuseColor = vec4(materialColor, 1) * .01 + texture2D(texture, vec2(vTexCord.x, 1-vTexCord.y));

    float cosTheta = clamp( dot(normal_modelSpace, light_pos), 0, 1);
    float dist = distance(position_modelSpace, light_pos); 
    vec4 finalCol =   matDiffuseColor * vec4(0.3,0.3,0.3, 1) + (cosTheta * matDiffuseColor * light_color) / (dist);
    if (finalCol.a < 0.1)
        discard;
    gl_FragColor = finalCol;
    //gl_FragColor = matDiffuseColor + 0.001 * cosTheta * light_color;
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
    debug {
        glGetProgramiv(progID, GL_LINK_STATUS, &result);
        glGetProgramiv(progID, GL_INFO_LOG_LENGTH, &logLength);
        char[] progLog = new char[logLength];
        glGetProgramInfoLog(progID, logLength, cast(GLsizei*)null, progLog.ptr);
        writeln("Linking program info log: ", progLog);
    }
    glDeleteShader(vertID);
    glDeleteShader(fragID);
    while ((error = glGetError()) != GL_NO_ERROR)
        writeln(" delete error!");

    return progID;
}
