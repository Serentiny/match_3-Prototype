#pragma once

#ifndef LUASCRIPT_H
#define LUASCRIPT_H

#include <string>
#include <iostream>
#include <lua.hpp>

class LuaScript
{
public:
	LuaScript(const std::string& filename);
	~LuaScript();

	std::string init();
	std::string move(const int& x, const int& y, const char& dir);
	std::string mix();
	std::string tick();

	bool isOk()
	{
		return L != 0 && error == 0;
	};
	bool needToTick;

private:
	lua_State* L;
	int error;
	std::string catchExceptions();
};

#endif