import std.stdio;
import std.conv;
import std.string;
import std.math;
import std.container;

import Window;
import Renderer;
import ResourceManager;
import gameobject;
import ObjLoader;

import derelict.sdl2.sdl;

enum ConnectionType {Server, Client, None};

struct Settings {
    // 1 server, 0 client, -1 non networked, -2 quit
    int windowHeight;
    int windowWidth;
    ConnectionType connection;
    int build_time;
    string ip_addr;
    string buildNum;
    bool running;
}

class Menu {
    Settings settings;
    Window window;
    Renderer renderer;
    Scene scene;
    Camera camera;
    ResourceManager resMan;
    this(Window window, Renderer renderer, Settings settings) {
        this.window = window;
        this.renderer = renderer;
        scene = new Scene();
        renderer.setScene(scene);
        this.settings = settings;
        resMan = getResourceManager();
        camera = new Camera(to!float(window.windowWidth)/window.windowHeight);
        camera.setTranslation(0,10,0);
        camera.moveRotation(0, -PI/2);
    }

    GameObject getTextObject(float x, float y, float height, string text) {
        float ratio;
        Texture textTex = resMan.getTextTexture(text.dup, &ratio);
        return new GameObject(x,y, ratio*height, -height, true, textTex);
    }

    Settings run() {
        GameObject background = new GameObject(-30,-2,-30,30,-1,30);
        background.setColor(10,10,10);

        float ratio; // x/y for text objects so we know how wide to make them

        // Note that getTextTexture is evaluated before the constructor, so ratio is updated properly
        GameObject title = getTextObject(-3.2,-3.5,3, "blankd");
        GameObject titleUnderline = new GameObject(-3.5,0,-4, 3.5,0,-4.04);

        GameObject serverTxt = getTextObject(-9,0,2, "server");
        GameObject clientTxt = getTextObject(-9,1.5,2, "client");
        GameObject testTxt = getTextObject(-9,3,2,"test");
        GameObject settingsTxt = getTextObject(-9,4.5,2,"settings");
        GameObject exitTxt = getTextObject(-9,6,2,"exit");

        GameObject selector = new GameObject(-9,0,0, -4,0,0.03);

        ObjLoader objloader = ResourceManager.getResourceManager.objLoader;
        GameObject player = new GameObject(0,0,0,0);
        GameObject flagR = new GameObject(0,0,0,0);
        GameObject flagB = new GameObject(0,0,0,0);
        objloader.open("flag.obj", flagR);
        objloader.open("flag.obj", flagB);
        objloader.open("Player.obj", player);
        flagR.x = 3;
        flagR.y = -2;
        flagR.rx = -PI/2;
        flagR.setColor(1,0,0);
        flagR.updateMatrix();
        flagB.x = 3;
        flagB.y = -2;
        flagB.rx = PI/2;
        flagB.setColor(0,0,1);
        flagB.updateMatrix();
        player.x = 5;
        player.y = -2;
        player.rx = -PI/2;
        player.ry = -PI/2;
        player.setColor(1,0,0);
        player.updateMatrix();

        scene.addPair(camera);
        scene.addToPair(camera, background);
        scene.addToPair(camera, title);
        scene.addToPair(camera, titleUnderline);
        scene.addToPair(camera, serverTxt);
        scene.addToPair(camera, clientTxt);
        scene.addToPair(camera, testTxt);
        scene.addToPair(camera, settingsTxt);
        scene.addToPair(camera, exitTxt);
        scene.addToPair(camera, selector);
        scene.addToPair(camera, flagR);
        scene.addToPair(camera, flagB);
        scene.addToPair(camera, player);
        
        SDL_Event event;
        bool continueMenu = true;
        int option = 0;
        int numOptions = 5;
        SDL_JoystickEventState(SDL_ENABLE);
        SDL_Joystick* joystick = SDL_JoystickOpen(0);
        while(continueMenu) {
            while (SDL_PollEvent(&event)) {
                //writeln(event.type);
                switch (event.type) {
                    case SDL_JOYHATMOTION:
                        if (event.jhat.value & SDL_HAT_UP)
                            option = (option-1+numOptions)%numOptions;
                        else if (event.jhat.value & SDL_HAT_DOWN)
                            option = (option+1)%numOptions;
                        break;
                        /*
                    case SDL_JOYAXISMOTION:
                        if ((event.jaxis.value < -3200) || (event.jaxis.value > 3200)) {
                            if (event.jaxis.axis == 0)
                                option = (option-1+numOptions)%numOptions;
                            else if (event.jaxis.axis == 1)
                                option = (option+1)%numOptions;
                        }
                        break;
                        */
                    case SDL_JOYBUTTONDOWN:
                        switch (event.jbutton.button) {
                            case 1:
                                continueMenu = false;
                                if (option == 1)
                                    settings.ip_addr = textEntry(-5,1.3, 1.2, "->server IP: ");
                                else if (option == 0)
                                    settings.build_time = to!int(textEntry(-5,-0.2, 1.2, "->build time: "));
                                break;
                            default:
                        }
                        break;
                    case SDL_KEYDOWN:
                        switch (event.key.keysym.sym) {
                            case SDLK_ESCAPE:
                                option = 4;
                                settings.running = false;
                                goto case;
                            case SDLK_RETURN:
                                if (option == 0) {
                                    settings.build_time = to!int(textEntry(-5,-0.2, 1.2, "->build time: "));
                                    settings.connection = ConnectionType.Server;
                                    continueMenu = false;
                                } else if (option == 1) {
                                    settings.ip_addr = textEntry(-5,1.3, 1.2, "->server IP: ");
                                    settings.connection = ConnectionType.Client;
                                    continueMenu = false;
                                } else if (option == 2) {
                                    settings.connection = ConnectionType.None;
                                    continueMenu = false;
                                } else if (option == 3) {
                                    settings.windowHeight = to!int(textEntry(-3,4.2, 1.2, "->window height: "));
                                    settings.windowWidth = to!int(textEntry(-3,4.2, 1.2, "->window width: "));
                                    window.resize(settings.windowWidth, settings.windowHeight);
                                } else if (option == 4) {
                                    continueMenu = false;
                                    settings.running = false;
                                }
                                break;
                            case SDLK_UP:
                                option = (option-1+numOptions)%numOptions;
                                break;
                            case SDLK_DOWN:
                                option = (option+1)%numOptions;
                                break;
                            default:
                        }
                        break;
                    default:
                }
            }

            selector.z = option * 1.5 - 0.2;
            selector.updateMatrix();

            //flag.rz += 0.001;
            flagR.ry += 0.005;
            flagB.ry += 0.005;
            flagR.updateMatrix();
            flagB.updateMatrix();
            renderer.draw();
        }

        scene.clearPair(camera);

        return settings;
    }


string textEntry(float x, float y, float height, string prompt) {
        GameObject promptTxt = getTextObject(x,y,height,prompt);
        scene.addToPair(camera, promptTxt);

        SDL_Event event;
        bool continueEntry = true;
        Array!(GameObject) entryObjs;
        char[] entryText;
        char[] oldEntryText;
        while(continueEntry) {
            while (SDL_PollEvent(&event)) {
                //writeln(event.type);
                switch (event.type) {
                    case SDL_KEYDOWN:
                        switch (event.key.keysym.sym) {
                            case SDLK_ESCAPE:
                                goto case;
                            case SDLK_RETURN:
                                continueEntry = false;
                                break;
                            case SDLK_UP:
                                break;
                            case SDLK_DOWN:
                                break;
                            case SDLK_0:
                            case SDLK_KP_0:
                                entryText ~= '0';
                                break;
                            case SDLK_1:
                            case SDLK_KP_1:
                                entryText ~= '1';
                                break;
                            case SDLK_2:
                            case SDLK_KP_2:
                                entryText ~= '2';
                                break;
                            case SDLK_3:
                            case SDLK_KP_3:
                                entryText ~= '3';
                                break;
                            case SDLK_4:
                            case SDLK_KP_4:
                                entryText ~= '4';
                                break;
                            case SDLK_5:
                            case SDLK_KP_5:
                                entryText ~= '5';
                                break;
                            case SDLK_6:
                            case SDLK_KP_6:
                                entryText ~= '6';
                                break;
                            case SDLK_7:
                            case SDLK_KP_7:
                                entryText ~= '7';
                                break;
                            case SDLK_8:
                            case SDLK_KP_8:
                                entryText ~= '8';
                                break;
                            case SDLK_9:
                            case SDLK_KP_9:
                                entryText ~= '9';
                                break;
                            case SDLK_PERIOD:
                            case SDLK_KP_PERIOD:
                                entryText ~= '.';
                                break;
                            case SDLK_BACKSPACE:
                                entryText = entryText[0..(entryText.length >0 ? entryText.length-1 :0)];
                                break;
                            default:
                        }
                        break;
                    default:
                }

                if (entryText != oldEntryText) {
                    if (oldEntryText.length < entryText.length) {
                        char[] letterString;
                        letterString ~= entryText[entryText.length-1];
                        float curX = (entryObjs.length ? entryObjs.back.rightx : promptTxt.rightx);
                        entryObjs ~= getTextObject(curX,y,height,letterString.dup);
                        scene.addToPair(camera, entryObjs.back);
                    } else if (oldEntryText.length > entryText.length) {
                        scene.removeFromPair(camera, entryObjs.back);
                        entryObjs.removeBack();
                    }
                    //writeln(entryText);
                    oldEntryText = entryText;
                }
            }

            renderer.draw();
        }
        scene.removeFromPair(camera, promptTxt);
        foreach (GameObject obj; entryObjs)
            scene.removeFromPair(camera, obj);
        return to!string(entryText);
    }
}
