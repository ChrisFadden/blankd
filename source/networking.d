import std.stdio;
import std.conv;

import derelict.sdl2.net;

immutable uint maxBufferSize = 512;

byte writeBuffer[maxBufferSize] = 0;
int bufferIndex;

byte readBuffer[maxBufferSize] = 0;
int readBufferSize = 0;

SDLNet_SocketSet socketSet;
TCPsocket socket;

// Returns whether or not the socket is still connected
bool readsocket(TCPsocket msocket, bool function(byte**, int) canHandle, int function(byte**, TCPsocket) func) {
	if (SDLNet_SocketReady(msocket)){
		if ((readBufferSize += SDLNet_TCP_Recv(msocket, (&readBuffer) + readBufferSize, maxBufferSize)) > 0) {
			byte* buf = cast(byte*)readBuffer;
			while (readBufferSize > 0){
				if (canHandle(&buf, readBufferSize))
					readBufferSize -= func(&buf, msocket);
				else
					break;
			}
			return true;
		} else {
			SDLNet_TCP_DelSocket(socketSet, msocket);
			SDLNet_TCP_Close(msocket);
			return false;
		}
	}
	return true;
}

byte peekbyte(byte** readBuffer){
	return *readBuffer[0];
}

byte readbyte(byte** readBuffer){
	byte b = *readBuffer[0];
	*readBuffer += 1;
	return b;
}

float readfloat(byte** readBuffer){
	byte[float.sizeof] outFloatArr = new byte[float.sizeof];
	for (int i = 0; i < float.sizeof; i++) {
		outFloatArr[i] = *readBuffer[0];
		*readBuffer += 1;
	}
	//*readBuffer += float.sizeof;
	float* outFloatP = cast(float*)(outFloatArr);
	return(*outFloatP);
}

void writebyte(byte b){
	writeBuffer[bufferIndex] = b;
	bufferIndex++;
}

void writefloat(float f){
	byte* fp = cast(byte*)&f;
	for (int i = 0; i < float.sizeof; i++) {
		writeBuffer[bufferIndex] = fp[i];
		bufferIndex++;
	}
}

void clearbuffer(){
	writeBuffer = 0;
	bufferIndex = 0;
}

bool sendmessage(TCPsocket msocket) {
	return sendmessage(msocket, true);
}

TCPsocket checkForNewClient(){
	if (SDLNet_SocketReady(socket) != 0) {
		TCPsocket newSocket = SDLNet_TCP_Accept(socket);
		SDLNet_TCP_AddSocket(socketSet, newSocket);
		return newSocket;
	}
	return null;
}

bool sendmessage(TCPsocket socket, bool clear){
	int sent = SDLNet_TCP_Send(socket, cast(void*)writeBuffer, bufferIndex);
	bool output = sent < bufferIndex ? false : true;
	if (clear){
		clearbuffer();
	}
	return output;
}

bool checkSockets(){
	return SDLNet_CheckSockets(socketSet, 0) > 0;
}

TCPsocket getSocket(){
	return socket;
}

void removeSocket(TCPsocket s){
	SDLNet_TCP_DelSocket(socketSet, s);
}

bool SDLNet_InitServer(ushort port, uint clients) {
	socketSet = SDLNet_Initialize(clients);

	IPaddress ip;

	if (SDLNet_ResolveHost(&ip, null, port) < 0) {
		writeln("SDLNet ResolveHost failed: ", to!string(cast(char*)SDLNet_GetError()));
		return false;
	}
	socket = SDLNet_TCP_Open(&ip);
	if (!socket) {
		writeln("SDLNet TCPOpen failed: ", to!string(cast(char*)SDLNet_GetError()));
		return false;
	}
	SDLNet_TCP_AddSocket(socketSet, socket);

	writeln("Initialized server on port ", port);

	return true;
}

bool SDLNet_InitClient(const char* host, ushort port) {
	socketSet = SDLNet_Initialize(1);

	IPaddress ip;

	if (SDLNet_ResolveHost(&ip, host, port) < 0) {
        writeln("SDLNet ResolveHost failure: ", to!string(cast(char*)SDLNet_GetError()));
        return false;
    }
    socket = SDLNet_TCP_Open(&ip);
    if (!socket) {
        writeln("SDLNet TCP_Open failure: ", to!string(cast(char*)SDLNet_GetError()));
        writeln("Could not connect to server. ");
        return false;
    }

    // Add our socket to our socket set
    SDLNet_TCP_AddSocket(socketSet, socket);

    return true;
}

void freesockets(){
	SDLNet_FreeSocketSet(socketSet);
	SDLNet_TCP_Close(socket);
}

SDLNet_SocketSet SDLNet_Initialize(uint socketSetSize) {

	// Initialize SDLNet
	if (SDLNet_Init() < 0) {
		// If we fail...
		writeln("SDLNet Init failure: ", to!string(cast(char*)SDLNet_GetError()));
		return null;
	}

	bufferIndex = 0;

	// Create a socket
	return SDLNet_AllocSocketSet(socketSetSize);
}
