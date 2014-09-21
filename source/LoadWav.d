/************************************************
	LoadWav.d;  A file for the sound processing
of the game blankd.  

Written by Marcus Godwin
September 20th 2014

**************************************************/



/***************************************
	Import Statements
*****************************************/
import std.file, std.stdio, std.string, std.conv;
import derelict.sdl2.mixer;




/*******************************************
	Load Wav Function

		Initializes a single wav file, set
	to be played at a later time

********************************************/

Mix_Chunk* loadWav(char* name)
{
	int audio_rate = 44100;			//Set the sample rate
	ushort audio_format = 0;		//Indicate audio format
	int audio_channels = 2;			//Indicate number of audio channels
	int audio_buffers = 8192;		//Set the audio buffers

	
	if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0) //error condition
	{
		writeln("ERROR WITH SDL AUDIO");
	}
	
	Mix_Chunk *sound = null;	//initialize the output sound variable
	sound = Mix_LoadWAV(name);	//Initialize the sound file
	return sound;				//retrun a pointer to the sound file
}




/******************************************************
	Initialize Sound Function

		Initializes all wav files held in the main
	directory, set to be played later.

******************************************************/

Mix_Chunk*[4] InitializeSound()
{
		char* musicName1 = cast(char*)"bullet.wav";
    	char* musicName2 = cast(char*)"Teleport.wav";
    	char* musicName3 = cast(char*)"Power_Up.wav";
	char* musicName4 = cast(char*)"hitByBullet.wav";	

    	Mix_Chunk* music1 = null;
    	Mix_Chunk* music2 = null;
    	Mix_Chunk* music3 = null;
	Mix_Chunk* music4 = null;	


    	music1 = loadWav(musicName1);
    	music2 = loadWav(musicName2);
    	music3 = loadWav(musicName3);
	music4 = loadWav(musicName4);

    	return [music2, music1, music3, music4];
}



/**********************************
	Play Sound Function

	   plays the sound file pointed
	to by the input.
***********************************/
void PlaySound(Mix_Chunk *sound)
{
	int channel;
	channel = Mix_PlayChannel(-1, sound, 0);
}


