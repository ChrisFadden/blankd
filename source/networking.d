import std.stdio;

import derelict.sdl2.net;

byte writeBuffer[512] = 0;
int bufferIndex;

SDLNet_SocketSet socketSet;
TCPsocket socket;

// Returns whether or not the socket is still connected
bool readsocket(TCPsocket msocket, (void)(*function)(byte[])) {
	if (SDLNet_SocketReady(msocket)){
		int len;
		if ((len = SDLNet_TCP_Recv(msocket, &readBuffer, 512)) > 0) {
			function(readBuffer);
			return true;
		} else {
			SDLNet_TCP_DelSocket(socketSet, msocket);
			SDLNet_TCP_Close(msocket);
			return false;
		}
	}
}

byte readbyte(byte[] readBuffer){
	byte b = readBuffer[0];
	readBuffer++;
	return b;
}

void writebyte(byte b){
	writeBuffer[bufferIndex] = b;
	iBuffer++;
}

void clearbuffer(){
	writeBuffer = 0;
	bufferIndex = 0;
}

bool sendmessage(TCPsocket msocket) {
	return sendmessage(msocket, true);
}

TCPSocket checkForNewClient(){
	if (SDLNet_SocketReady(socket) != 0) {
		TCPSocket newSocket = SDLNet_TCP_Accept(socket);
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
	return SDLNet__CheckSockets(socketSet, 0) > 0;
}

TCPsocket getSocket(){
	return socket;
}

bool SDLNet_InitServer(ushort port, uint clients) {
	socketSet = SDLNet_Initialize(clients);

	IPaddress ip;

	if (SDLNet_ResolveHost(&ip, null, port) < 0) {
		writeln("SDLNet ResolveHost failed: ", SDLNet_GetError());
		return false;
	}
	socket = SDLNet_TCP_Open(&ip);
	if (!socket) {
		writeln("SDLNet TCPOpen failed: ", SDLNet_GetError());
		return false;
	}
	SDLNet_TCP_AddSocket(socketSet, socket);

	return true;
}

bool SDLNet_InitClient(const char* host, ushort port) {
	socketSet = SDLNet_Initialize(1);

	IPaddress ip;

	if (SDLNet_ResolveHost(&ip, host, port) < 0) {
        writeln("SDLNet ResolveHost failure: ", SDLNet_GetError());
        return false;
    }
    socket = SDLNet_TCP_Open(&ip);
    if (!socket) {
        writeln("SDLNet TCP_Open failure: ", SDLNet_GetError());
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
		writeln("SDLNet Init failure: ", SLDNet_GetError());
		return false;
	}
	return true;

	bufferIndex = 0;

	// Create a socket
	SDLNet_SocketSet socketSet = SDLNet_AllocSocketSet(socketSetSize);
}