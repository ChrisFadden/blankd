import std.container;
import std.conv;
import std.algorithm;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import gameobject;
import Window;
import Camera;
import Scene;
import stdlib;

class Renderer {
    Window window;
    Camera camera;
    Scene scene;
    bool isDead;

    this(Window window) {
        this.window = window;

        glEnable(GL_BLEND);
        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);
        glClearColor(.5f,.5f,1f,1f);
    }

    void setScene(Scene scene) {
        this.scene = scene;
    }

    void draw() {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        foreach (Pair!(Camera, Array!(GameObject)) i; scene.data)
            foreach (GameObject obj; i.second)
                if (obj.visible)
                    obj.draw(i.first);

        window.flip();
    }
}
