import std.container;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import gameobject;
import Window;
import Camera;

class Renderer {
    Window window;
    Camera camera;
    Array!(GameObject) objects;

    this(Window* window, Camera* camera) {
        this.window = *window;
        this.camera = *camera;
        glEnable(GL_DEPTH_TEST);
        //glEnable(GL_CULL_FACE);
        glClearColor(.5f,.5f,1f,1f);
    }

    void register(GameObject obj) {
        objects ~= obj;
    }

    void draw(GameObject o = null) {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        foreach (GameObject obj; objects)
            if (obj.visible)
                obj.draw(camera);

        if (o !is null){
            o.draw(camera);
        }
        window.flip();
    }
}
