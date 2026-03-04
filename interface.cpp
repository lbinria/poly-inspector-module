// NOT MODIFY HERE !
// interface is used by the viewer to initialize the class
// class will register all custom functions & types needed into lua
// Note: You should modify register constructor implementation to register your own functions & types
#include "script.h"

#if defined(__linux__) || defined(__APPLE__)

extern "C" {
	MyScript* allocator(IApp &app, sol::state &lua) {
		return new MyScript(app, lua);
	}

	void deleter(MyScript *ptr) {
		delete ptr;
	}
}

#endif

#ifdef WIN32
extern "C"
{
	__declspec (dllexport) MyScript* allocator(IApp &app, sol::state &lua) {
		return new MyScript(app, lua);
	}

	__declspec (dllexport) void deleter(MyScript *ptr) {
		delete ptr;
	}

}
#endif