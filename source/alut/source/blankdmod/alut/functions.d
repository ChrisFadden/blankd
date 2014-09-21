module blankdmod.alut.functions;

import std.stdio;
public import blankdmod.alut.types;

private {
	import core.stdc.stdio;
	import core.stdc.stdarg;
	import derelict.util.system;
	import derelict.util.loader;

	enum libNames ="libalut.so";
}


extern( C ) @nogc nothrow {
	//alut.h
	alias da_alutLoadWAVFile = void function (ALbyte *, ALenum *, void **, ALsizei *, ALsizei *, ALboolean *);


}

__gshared {
	da_alutLoadWAVFile alutLoadWAVFile;
}


void moduleFunc()
{
	writeln("This is a function from a module!");
}

class blankdModLoader : SharedLibLoader {
	public this() {
		super(libNames);
	}

	protected override void loadSymbols(){
		bindFunc( cast(void**)&alutLoadWAVFile, "alutLoadWAVFile");
	}
}