import std.stdio;
import core.thread;
import std.string;
import std.math;
import std.conv;


import derelict.opengl3.gl3;
import derelict.sdl2.sdl;
import derelict.sdl2.net;
import derelict.sdl2.mixer;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import ShaderProgram;
import LoadWav;
import Texture;
import ObjLoader;

static ResourceManager getResourceManager() {
    static ResourceManager instance;
    if (instance)
        return instance;
    instance = new ResourceManager();
    return instance;
}

class ResourceManager {

	ShaderProgram[bool] shaders;
	Mix_Chunk*[] sounds; 
    //TTF_Font*[uint] fonts;
    SDL_Surface*[char] fontCharacters;
	Texture[string] textures;
    ObjLoader objLoader;

	/*
	** The other items like textures and sounds can go here too!
	*/

	this()
	{
		shaders[true] = new ShaderProgram(true);
		shaders[false] = new ShaderProgram(false);
        setupFont();
        objLoader = new ObjLoader;
    }

	~this()
	{}

	ShaderProgram getShader(bool key)
	{
        return shaders[key];
	}

	void loadSound(char[] fileName)
	{
		sounds ~= loadWav(fileName.ptr);
	}

	Mix_Chunk*[] getSound()
	{
		return sounds;
	}

    SDL_Surface* renderText(char[] text, float *ratio) {
        uint width = 0;
        uint height = 0;
        for (uint i = 0; i < text.length; i++) {
            width += fontCharacters[text[i]].w;
            height = fontCharacters[text[i]].h > height ? fontCharacters[text[i]].h : height;
        }
        SDL_Surface* dest = SDL_CreateRGBSurface(0, width, height, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
        if (!dest)
            writeln("Could not create surface");
        uint runningX = 0;
        for (uint i = 0; i < text.length; i++) {
            SDL_Rect destRec = {runningX,0, 0,0};
            SDL_BlitSurface(fontCharacters[text[i]], null, dest, &destRec);
            runningX += fontCharacters[text[i]].w;
        }
        *ratio = to!float(runningX)/height;
        return dest;
    }

    void setupFont() {
        uint size = 108; // Crashes if we load more than once, we'll only do one high res size :(
        writeln("Loading font of size ", size);
        TTF_Font* font = TTF_OpenFont("mplus-1c-light.ttf".dup.ptr, size);
        if (!font) {
            string err = to!string(cast(char*)TTF_GetError());
            writeln("TTF Error: ", err);
            return;
        }
        SDL_Color colorS = {1,1,0};
        for (uint i = 0; i < 1 << (char.sizeof * 8); i++) {
            char[2] charString;
            charString[0]= to!char(i);
            charString[1] = '\0';
            fontCharacters[to!char(i)] = TTF_RenderText_Blended(font, charString.ptr, colorS);
        }
        TTF_CloseFont(font);
    }
	Texture getTexture(string name) 
	{
        if (Texture* tex = (name in textures))
            return *tex;
        int error;
        while ((error = glGetError()) != GL_NO_ERROR)
            writeln("Before texture error!", error);
        SDL_Surface* surface = IMG_Load(name.ptr);
        if (!surface) {
            writeln("Could not load ", name);
            return null;
        }
        textures[name] = new Texture(name.dup, surface);
        return textures[name];
	}
    Texture getTextTexture(char[] text, float *ratio) {
        SDL_Surface* surface = renderText(text, ratio);
        if (!surface) {
            writeln("Could not render ", text);
            return null;
        }
        return new Texture(text, surface);
    }
}
