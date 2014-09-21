import std.file, std.stdio, std.string, std.conv;
import blankdmod.alut.functions;

void loadWav(char* name)
{
	ALenum format; 
	ALvoid* data; 
	ALsizei sz; 
	ALsizei freq;
	ALboolean loop = false;
	writeln("ALOHA alut!!!");
	alutLoadWAVFile(name,&format,&data,&sz,&freq,&loop);
	writeln("ALOHA 2 alut!!!");
	writeln(data);
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