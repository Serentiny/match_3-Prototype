#include "luaScript.h"
#include "consoleVisualizer.h"

#include <regex>
#include <map>
#include <string>
#include <iostream>

void main()
{
	TableVisualizer vis;
	vis.initTable();

	LuaScript script("script.lua");
	if (script.isOk())
	{
		auto dump = script.init();
		if (script.isOk())
			vis.updateTable(dump);
	}

	std::regex moveCommand = std::regex("^m *[0-9] *[0-9] *[lrud]$");
	std::string input;
	int sleepTime = 200;

	while (true)
	{
		std::getline(std::cin, input);
		vis.updateLastInput(input);

		if (!script.isOk() || input == "q")
			return;
		else if (input == "mix")
		{
			auto dump = script.mix();
			if (script.isOk())
				vis.updateTable(dump);
		}
		else if (std::regex_match(input, moveCommand))
		{
			input.erase(std::remove_if(input.begin(), input.end(), ::isspace), input.end());
			auto dump = script.move((int)(input[1] - '0') + 1, (int)(input[2] - '0') + 1, input[3]);
			if (script.isOk())
				vis.updateTable(dump);

			while (script.needToTick)
			{
				Sleep(sleepTime);
				auto dump = script.tick();
				if (script.isOk())
					vis.updateTable(dump);
			}
		}
		vis.setReadyToInput();
	}
};