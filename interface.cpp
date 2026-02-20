// NOT MODIFY HERE !
// interface is used by the viewer to initialize the Registerer class
// Registerer class will register all custom functions & types needed into lua
// Note: You should modify register constructor implementation to register your own functions & types
#include "Registerer.h"

#if defined(__linux__) || defined(__APPLE__)

extern "C" {
	Registerer* allocator(IApp &app, sol::state &lua) {
		return new Registerer(app, lua);
	}

	void deleter(Registerer *ptr) {
		delete ptr;
	}
}

#endif

#ifdef WIN32
extern "C"
{
	__declspec (dllexport) Registerer* allocator(IApp &app, sol::state &lua) {
		return new Registerer(app, lua);
	}

	__declspec (dllexport) void deleter(Registerer *ptr) {
		delete ptr;
	}

}
#endif