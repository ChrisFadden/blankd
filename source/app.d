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

