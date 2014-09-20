import std.stdio;
import core.thread;
import std.string;

import Window;
import Renderer;
import gameobject;
import blankdmod.myo.functions;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

import networking;

bool running;

void main() {
    DerelictGL3.load();
    DerelictSDL2.load();
    DerelictSDL2Net.load();

    writeln("Server or client or no networking? s/c/n");
    char[] buf;
    stdin.readln(buf);
    int server;
    switch (buf[0]){
        case 's':
        server = 1;
        break;
        case 'c':
        server = 0;
        break;
        default:
        server = -1;
        break;
    }

    Window window = new Window("HackGT - blankd");
    window.init();
    // Has to reload after we have a context
    DerelictGL3.reload();

    writeln("Starting interesting code");

    Camera camera = new Camera();
    writeln("Finished camera");
    Renderer renderer = new Renderer(window, camera);
    writeln("Finished renderer");

    GameObject go1 = new GameObject;
    writeln("Finished making game object");
    go1.visible = true;
    writeln(go1.visible);
    go1.x = 0.0;
    go1.y = 0.0;
    go1.z = 0.0;
    renderer.register(go1);
    writeln("Bout to draw");
    renderer.draw();
    writeln("Done drawing");
    moduleFunc();
    window.pause(2000);

    if (server == 1) {
        SDLNet_InitServer(1234, 20);
        running = true;
        TCPsocket client;
        while (running) {
            if (checkSockets() > 0){
                TCPsocket tempClient = checkForNewClient();
                if (tempClient !is null){
                    client = tempClient;
                    writebyte(1);
                    sendmessage(client);
                }

                if (client !is null)
                    readsocket(client, &basic);
            }
        }
    } else if (server == 0){

    }

    //Finish and quit
    window.quit();
    freesockets();
    SDLNet_Quit();
    SDL_Quit();
}

void basic(byte* array) {
    byte a = readbyte(array);
}

