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
    }

    void register(GameObject obj) {
        objects ~= obj;
    }

    /*
    void reregister(GameObject obj) {
        objects -= obj;
        objects ~= obj;
    }
    */

    void draw(GameObject o = null) {
        //foreach (GameObject toAddObj; toAddObjects)
        //    objects ~= toAddObj;
        //toAddObjects.clear();
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        foreach (GameObject obj; objects)
            obj.draw(camera);

        if (o !is null){
            o.draw(camera);
        }
        window.flip();
    }
}
