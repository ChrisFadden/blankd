import std.file, std.stdio, std.string, std.conv;
//import blankdmod.alut.functions;
import derelict.sdl2.mixer;

void loadWav(char* name)
{
	/*ALenum format; 
	ALvoid* data; 
	ALsizei sz; 
	ALsizei freq;
	ALboolean loop = false;*/
	DerelictSDL2Mixer.load();
	writeln("ALOHA alut!!!");
	int audio_rate = 44100;
	ushort audio_format = 0;
	int audio_channels = 2;
	int audio_buffers = 8192;

	int flags = Mix_Init(0);
	writeln(flags);
	flags = Mix_Init(~0);
	writeln(flags);
	writeln("Error on init");
	if(Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0)
	{
		writeln("ERROR WITH SDL AUDIO AGOJAOPREJPQPGFNAG");
	}
	
	writeln("We are almost there....");
	//alutLoadWAVFile(name,&format,&data,&sz,&freq,&loop);
	//writeln(data);
	Mix_Chunk *sound = null;
	sound = Mix_LoadWAV(name);

	int channel;

	channel = Mix_PlayChannel(-1, sound, -1);
	if(channel == -1)
		writeln("ANOTHER ERROR WITH AUDIO EOAPEFAJPEAJPFJAG");

}




/*

void readWavFile(string name, out ALenum format, out ALvoid* data, out ALsizei sz, out ALsizei freq)

struct WAV_HEADER{
            char RIFF[4];                //Riff Header
            ulong ChunkSize;    //Riff Chunk Size
            char     WAVE[4];            //WAVE HEADER
            char     fmt[4];                //FMT header
            ulong Subchunk1Size;//Size of the FMT chunk
            ushort AudioFormat; //Audio format
            ushort NumOfChan;    //1 = Mono, 2 = Stereo
            ulong SamplesPerSec;//Samp Freq in Hz
            ulong bytesPerSec;    // bytes per sec
            ushort blockAlign;    //2 = 16-bit mono, 4 = 16-bit stereo
            ushort bitsPerSample;//Number of bits per sample
            char Subchunk2ID[4];     //"data" string
            ulong Subchunk2Size;     //Sampled data length

        }


*/