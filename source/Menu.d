import std.stdio;
import std.conv;
import std.math;
import std.container;

import Window;
import Renderer;
import gameobject;

import derelict.sdl2.sdl;

struct Settings {
    // 1 server, 0 client, -1 non networked, -2 quit
    int server;
    string ip_addr;
}

class Menu {
    Settings settings;
    Window window;
    Renderer renderer;
    Camera menuCam;
    this(Window window, Renderer renderer) {
        this.window = window;
        this.renderer = renderer;
        menuCam = new Camera();
        menuCam.setTranslation(0,10,0);
        menuCam.moveRotation(0, -PI/2);
    }

    Settings run() {
        Settings settings = {-1, "127.0.0.1"};
        this.settings = settings;
        GameObject background = new GameObject(-30,-2,-30,30,-1,30);
        background.setRGB(10,10,10);

        GameObject title = new GameObject(-3,-3,6,-3,true, new Texture("blankd".dup, 1,1,0));

        GameObject serverTxt = new GameObject(-9,0,3,-1.5,true, new Texture("server".dup, 1,1,0));
        GameObject clientTxt = new GameObject(-9,1.5,3,-1.5,true, new Texture("client".dup, 1,1,0));
        GameObject testTxt = new GameObject(-9,3,3,-1.5,true, new Texture("test".dup, 1,1,0));
        GameObject exitTxt = new GameObject(-9,4.5,3,-1.5,true, new Texture("exit".dup, 1,1,0));

        GameObject selector = new GameObject(-9,0,-0.2,-4,-0.1,-0.22);

        renderer.setCamera(menuCam);
        renderer.register(background);
        renderer.register(title);
        renderer.register(serverTxt);
        renderer.register(clientTxt);
        renderer.register(testTxt);
        renderer.register(exitTxt);
        renderer.register(selector);
        
        SDL_Event event;
        bool continueMenu = true;
        int option = 0;
        int numOptions = 4;
        SDL_JoystickEventState(SDL_ENABLE);
        SDL_Joystick* joystick = SDL_JoystickOpen(0);
        while(continueMenu) {
            while (SDL_PollEvent(&event)) {
                writeln(event.type);
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
                                settings.ip_addr = textEntry(-9,2, "Server IP: ");
                                break;
                            default:
                        }
                        break;
                    case SDL_KEYDOWN:
                        switch (event.key.keysym.sym) {
                            case SDLK_ESCAPE:
                                option = 3;
                                goto case;
                            case SDLK_RETURN:
                                continueMenu = false;
                                if (option == 1)
                                    settings.ip_addr = textEntry(-9,2, "Server IP: ");
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

            selector.z = option * 1.5;
            selector.updateMatrix();

            renderer.draw();
        }

        renderer.clearObjects();

        settings.server = 1-option;
        return settings;
    }


    string textEntry(int x, int y, string prompt) {
        GameObject promptTxt = new GameObject(-5,2.5,3,-1.5,true, new Texture(prompt.dup, 1,1,0));
        //GameObject exitTxt = new GameObject(-9,4.5,3,-1.5,true, new Texture("exit".dup, 1,1,0));
        renderer.register(promptTxt);

        SDL_Event event;
        bool continueEntry = true;
        Array!(GameObject) entryObjs;
        char[] entryText;
        char[] oldEntryText;
        while(continueEntry) {
            while (SDL_PollEvent(&event)) {
                writeln(event.type);
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
            }

            if (entryText != oldEntryText) {
                if (oldEntryText.length > entryText.length) {
                    char[] letterString;
                    letterString ~= entryText[entryText.length-1];
                    entryObjs ~= new GameObject(-5 + entryText.length,5.5,3,-1.5,true, new Texture(letterString.dup, 1,1,0));
                    renderer.register(entryObjs.back);
                } else if (oldEntryText.length > entryText.length) {
                    renderer.remove(entryObjs.back);
                    entryObjs.removeBack();
                }
                writeln(entryText);
                oldEntryText = entryText;
            }

            renderer.draw();
        }
        return to!string(entryText);
    }
}
