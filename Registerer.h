#pragma once

// Salamesh core
#include <app_interface.h>
#include <script.h>

#define SOL_ALL_SAFETIES_ON 1
#include <sol/sol.hpp>

#include "script.h"

struct Registerer final : public Script {

	// Modify constructor body in order to
	// register your functions / types here... using sol2 lib
	Registerer(IApp &app, sol::state &lua) : Script(app) {

		// Example, registering some functions to lua script
		lua.set_function("get_radiuses", &getRadiuses);
		lua.set_function("test", &test);
		lua.set_function("debug_lines", [](IApp &app, Model &model, std::vector<float> &radiuses) {
			return debugLines(app, model, radiuses);
		});

		lua.set_function("iterate_vertices", &iterate_vertices);
		lua.set_function("get_vertices", &get_vertices);
		
	}

};