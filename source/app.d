import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;

void main() {
    Window window = new Window("HackGT - blankd");
    window.init();

    Camera camera = new Camera();
    Renderer renderer = new Renderer(window, camera);

    GameObject go1 = new GameObject;
    go1.visible = true;
    writeln(go1.visible);
    go1.coords[0] = 0.0;
    go1.coords[1] = 1.0;
    go1.coords[2] = 2.0;
    writeln(go1.coords);
    renderer.register(go1);
    renderer.draw();

    //Finish and quit
    window.pause(2000);
    window.quit();
}

