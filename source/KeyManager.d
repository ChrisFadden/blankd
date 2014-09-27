import std.stdio;
import std.string;
import std.container;

import Window;
import Renderer;
import Menu;
import gameobject;
import GameManager;
import BlockBuilder;
import ObjLoader;
import Player;
import ResourceManager;

import networking;

import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;

// http://www.libsdl.org/release/SDL-1.2.15/docs/html/sdlkey.html

class KeyManager {
private GameManager gm;

	this(GameManager g) {
		this.gm = g;
	}

	~this(){}

	void handleGameplayInput(SDL_Event *event) {

		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYAXISMOTION:
				float deadzone = 3200f;

				if ((event.jaxis.value < -deadzone) || (event.jaxis.value > deadzone)){
					float value;
					if (event.jaxis.value > 0)
						value = (short.max/(short.max-deadzone))*((event.jaxis.value-deadzone)/cast(float)short.max);
					else
						value = (short.max/(short.max-deadzone))*((event.jaxis.value+deadzone)/cast(float)short.max);	

					if (event.jaxis.axis == 0) {
						gm.lrAmnt = value;
					} if (event.jaxis.axis == 1) {
						gm.fbAmnt = value;
					} else if (event.jaxis.axis == 2) {
						gm.scanHoriz = value;
					} else if (event.jaxis.axis == 5) {
						gm.scanVert = value;
					}
				} else {
					if (event.jaxis.axis == 0){
						gm.lrAmnt = 0;
					} else if (event.jaxis.axis == 1) {
						gm.fbAmnt = 0;
					} else if (event.jaxis.axis == 2) {
						gm.scanHoriz = 0;
					} else if (event.jaxis.axis == 5) {
						gm.scanVert = 0;
					}
				}
				break;
				case SDL_JOYBUTTONDOWN:
					switch(event.jbutton.button){
						case 1:
						gm.jump();
						break;
						case 7:
						gm.shoot();
						break;
						default:
						break;
					}
					//debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_JOYBUTTONUP:
					switch(event.jbutton.button){
						case 3:
                        gm.swapMode();
						break;

						default:
						break;
					}
					//debug writeln("Button ", event.jbutton.button);
				break;
				case SDL_MOUSEBUTTONDOWN:
					switch(event.button.button){
						case SDL_BUTTON_LEFT:
							gm.shoot();
							break;
						default:
						break;
					}
				break;
                case SDL_MOUSEMOTION:
                    int midx = gm.window.width()/2;
                    int midy = gm.window.height()/2;
                    int x = event.motion.x;
                    int y = event.motion.y;
                    int difx = midx-x;
                    int dify = midy-y;
                    gm.camera.moveRotation(difx/400f, dify/400f);
                    SDL_WarpMouseInWindow(gm.window.window, midx, midy);
                    break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							gm.running = false;
							break;
						case SDLK_w:
							gm.fbAmnt = -1;
						break;
						case SDLK_s:
							gm.fbAmnt = 1;
						break;
						case SDLK_a:
							gm.lrAmnt = -1;
						break;
						case SDLK_d:
							gm.lrAmnt = 1;
						break;
						case SDLK_q:
							gm.scanHoriz = -0.5;
							break;
						case SDLK_e: 
							gm.scanHoriz = 0.5;
						break;
						case SDLK_SPACE:
							gm.jump();
						break;
						default:
						break;
					}
					break;

				case SDL_KEYUP:
					switch(event.key.keysym.sym){
						case SDLK_w:
							gm.fbAmnt = 0;
						break;
						case SDLK_s:
							gm.fbAmnt = 0;
						break;
						case SDLK_a:
							gm.lrAmnt = 0;
						break;
						case SDLK_d:
							gm.lrAmnt = 0;
						break;
						case SDLK_q:
							gm.scanHoriz = 0;
							break;
						case SDLK_e: 
							gm.scanHoriz = 0;
							break;
						case SDLK_g:
							if(gm.server == -1)
								gm.swapMode();
						break;
						default:
						break;
					}
					break;
				default:
				break;
			}
		}
	}

	void handleMapMakerInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
				case SDL_JOYBUTTONDOWN:
					switch(event.jbutton.button){
						case 1:
						gm.placeBlock();
							break;
						case 2:
						gm.quitBlock();
							break;
						case 5:
						gm.raiseBlock();
							break;
						case 4:
						gm.lowerBlock();
							break;
						case 6:
						gm.udAmnt = -.25f;
							break;
						case 7:
						gm.udAmnt = .25f;
							break;
						case 10:
						gm.rotateViewRight();
							break;
						default:
						break;
					}
					//writeln(event.jbutton.button);
				break;
				case SDL_JOYBUTTONUP:
					switch(event.jbutton.button){
						case 6:
						gm.udAmnt = 0f;
							break;
						case 7:
						gm.udAmnt = 0f;
							break;
						case 3:
						if(gm.server == -1)
							gm.swapMode();
							break;
						default:
						break;
					}
				break;
				case SDL_JOYHATMOTION:
					if (event.jhat.value & SDL_HAT_UP) {
						gm.moveBlockUp();
					} else if (event.jhat.value & SDL_HAT_RIGHT) {
						gm.moveBlockRight();
					} else if (event.jhat.value & SDL_HAT_DOWN) {
						gm.moveBlockDown();
					} else if (event.jhat.value & SDL_HAT_LEFT) {
						gm.moveBlockLeft();
					}
				break;
				case SDL_JOYAXISMOTION:
				float deadzone = 3200f;
				if ((event.jaxis.value < -deadzone) || (event.jaxis.value > deadzone)){
					float value;
					if (event.jaxis.value > 0)
						value = (short.max/(short.max-deadzone))*((event.jaxis.value-deadzone)/cast(float)short.max);
					else
						value = (short.max/(short.max-deadzone))*((event.jaxis.value+deadzone)/cast(float)short.max);
					if (event.jaxis.axis == 0) {
						if (gm.builder.dir == 0)
							gm.lrAmnt = value;
						else if (gm.builder.dir == 1)
							gm.fbAmnt = -value;
						else if (gm.builder.dir == 2)
							gm.lrAmnt = -value;
						else if (gm.builder.dir == 3)
							gm.fbAmnt = value;
					} else if (event.jaxis.axis == 1) {
						if (gm.builder.dir == 0)
							gm.fbAmnt = value;
						else if (gm.builder.dir == 1)
							gm.lrAmnt = value;
						else if (gm.builder.dir == 2)
							gm.fbAmnt = -value;
						else if (gm.builder.dir == 3)
							gm.lrAmnt = -value;
					}
				} else {
					if (event.jaxis.axis == 0){
						if (gm.builder.dir%2 == 0)
							gm.lrAmnt = 0;
						else
							gm.fbAmnt = 0;
					} else if (event.jaxis.axis == 1) {
						if (gm.builder.dir%2 == 0)
							gm.fbAmnt = 0;
						else
							gm.lrAmnt = 0;
					} 
				}
				break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							gm.running = false;
							break;
						case SDLK_a:
							gm.moveBlockLeft();
							break;
						case SDLK_d:
							gm.moveBlockRight();
							break;
						case SDLK_w:
							gm.moveBlockUp();
							break;
						case SDLK_s:
							gm.moveBlockDown();
							break;
						case SDLK_SPACE:
						case SDLK_RETURN:
							gm.placeBlock();
							break;
						case SDLK_r:
							gm.raiseBlock();
							break;
						case SDLK_f:
							gm.lowerBlock();
							break;
						case SDLK_o:
							gm.rotateViewRight();
							break;
						case SDLK_u:
							gm.rotateViewLeft();
							break;
						case SDLK_q:
							gm.quitBlock();
							break;
						case SDLK_i:
							gm.moveCameraForward();
							//fbAmnt = -1f;
							break;
						case SDLK_j:
							//lrAmnt = 1f;
							gm.moveCameraLeft();
							break;
						case SDLK_k:
							//fbAmnt = 1f;
							gm.moveCameraBack();
							break;
						case SDLK_l:
							//lrAmnt = -1f;
							gm.moveCameraRight();
							break;
						case SDLK_SEMICOLON:
							gm.moveCameraDown();
							break;
						case SDLK_p:
							gm.moveCameraUp();
							break;
						default:
						break;
					}
				break;
				case SDL_KEYUP:
					switch(event.key.keysym.sym){
						case SDLK_g:
                        if (gm.server == -1)
                            gm.swapMode();
                        break;
                        default:
                        break;
					}
				break;
				default:
				break;
			}
		}
	}

	void handleWaitingInput(SDL_Event *event) {
		while (SDL_PollEvent(event)) {
			switch(event.type){
                case SDL_JOYBUTTONDOWN:
                    switch (event.jbutton.button) {
                        case 1:
							if (gm.server != 0){
								foreach (Player p ; gm.players){
									clearbuffer();
									writebyte(gm.MSG_BEGINBUILD);
									sendmessage(p.mySocket);
								}
								gm.beginBuildPhase();
							}
                            break;
                        default:
                    }
                    break;
				case SDL_KEYDOWN:
					switch(event.key.keysym.sym){
						case SDLK_ESCAPE:
							gm.running = false;
							break;
						case SDLK_RETURN:
							if (gm.server != 0){
								foreach (Player p ; gm.players){
									clearbuffer();
									writebyte(gm.MSG_BEGINBUILD);
									sendmessage(p.mySocket);
								}
								gm.beginBuildPhase();
							}
							break;
						default:
							break;
					}
					break;
				default:
					break;
			}
		}
	}
}