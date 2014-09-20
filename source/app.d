import std.stdio;
import core.thread;
import std.string;

import Window;

void main() {
    Window window = new Window("HackGT - blankd");
    window.init();
    window.flip();
    window.pause(2000);
    window.quit();
}

