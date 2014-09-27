import std.container;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;

import gameobject;
import Window;
import Camera;

class Renderer {
    Window window;
    Camera camera;
    Camera guiCam;
    Array!(GameObject) objects;
    GameObject reticle;

    this(Window window) {
        this.window = window;
        guiCam = new Camera();
        guiCam.setTranslation(0,0,2);
        reticle = new GameObject(-.01,-.01,-.01, .01,.01,.01);
        reticle.z = 1;
        reticle.visible = true;
        reticle.updateMatrix();
        glEnable(GL_BLEND);
        glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);
        glClearColor(.5f,.5f,1f,1f);
    }

    void setCamera(Camera camera) {
        this.camera = camera;
    }

    void register(GameObject obj) {
        objects ~= obj;
    }

    void remove(GameObject obj) {
        objects.remove(obj);
    }

    void clearObjects() {
        objects.clear();
    }

    void draw(GameObject o = null) {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        foreach (GameObject obj; objects)
            if (obj.visible)
                obj.draw(camera);

        if (o !is null){
            o.draw(camera);
        }
        reticle.draw(guiCam);
        window.flip();
    }
}
