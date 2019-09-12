#include "luaScript.h"

LuaScript::LuaScript(const std::string& filename)
{
	L = luaL_newstate();
	error = luaL_dofile(L, filename.c_str());
	if (error)
	{
		printf("Cannot dofile: %s", lua_tostring(L, -1));
		lua_pop(L, 1);
		L = 0;
	}

	if (L)
		luaL_openlibs(L);
}

LuaScript::~LuaScript()
{
	if (L)
		lua_close(L);
}

std::string LuaScript::init()
{
	lua_getglobal(L, "init");
	error = lua_pcall(L, 0, 1, 0);
	if (error)
		return catchExceptions();
	std::string result = lua_tostring(L, -1);
	return result;
}

std::string LuaScript::move(const int& x, const int& y, const char& dir)
{
	lua_getglobal(L, "move");
	lua_pushnumber(L, x);
	lua_pushnumber(L, y);
	lua_pushlstring(L, &dir, 1);
	error = lua_pcall(L, 3, 2, 0);
	if (error)
		return catchExceptions();
	needToTick = lua_toboolean(L, -1);
	lua_pop(L, 1);
	std::string result = lua_tostring(L, -1);
	return result;
}

std::string LuaScript::mix()
{
	lua_getglobal(L, "mix");
	error = lua_pcall(L, 0, 1, 0);
	if (error)
		return catchExceptions();
	std::string result = lua_tostring(L, -1);
	return result;
}

std::string LuaScript::tick()
{
	lua_getglobal(L, "tick");
	error = lua_pcall(L, 0, 2, 0);
	if (error)
		return catchExceptions();
	needToTick = lua_toboolean(L, -1);
	lua_pop(L, 1);
	std::string result = lua_tostring(L, -1);
	return result;
}

std::string LuaScript::catchExceptions()
{
	printf("LUA error: %s", lua_tostring(L, -1));
	lua_pop(L, 1);
	return "";
}