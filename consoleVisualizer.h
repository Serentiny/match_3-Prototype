#pragma once

#ifndef CONSOLEDRAW_H
#define CONSOLEDRAW_H

#include <windows.h>
#include <string>
#include <iostream>
#include <map>

struct TableVisualizer
{
public:
	void initTable()
	{
		SetConsoleCursorPosition(hConsole, coordZero);
		std::cout << "   0 1 2 3 4 5 6 7 8 9" << std::endl;
		std::cout << "  --------------------" << std::endl;
		std::cout << "0|"                     << std::endl;
		std::cout << "1|"                     << std::endl;
		std::cout << "2|"                     << std::endl;
		std::cout << "3|"                     << std::endl;
		std::cout << "4|"                     << std::endl;
		std::cout << "5|"                     << std::endl;
		std::cout << "6|"                     << std::endl;
		std::cout << "7|"                     << std::endl;
		std::cout << "8|"                     << std::endl;
		std::cout << "9|"                     << std::endl;
		std::cout << ""                       << std::endl;

		std::cout << "  Commands:" << std::endl;
		std::cout << "m x y d - Move crystal from coord (x:y) to direction 'd'(l-left, r-right, u-up, d-down)" << std::endl;
		std::cout << "q - Quit"    << std::endl;
		std::cout << ""            << std::endl;

		std::cout << "  Input:" << std::endl;
		std::cout << ">> "      << std::endl;
		std::cout << ""         << std::endl;

		std::cout << "  Last input:" << std::endl;
		std::cout << ">> "           << std::endl;
		std::cout << ""              << std::endl;
		SetConsoleCursorPosition(hConsole, coordInput);
	};

	void updateTable(const std::string& dump)
	{
		if (dump == "")
			return;
		// на вход приходит dim*dim*crystalStructSize символов, описывающих всю таблицу
		for (int y = 0; y < dim; y++)
			for (int x = 0; x < dim; x++)
			{
				auto stoneStructDump = dump.substr(crystalStructSize * (x + y * dim), crystalStructSize);
				updateCrystal(x, y, stoneStructDump);
			}
		setReadyToInput();
	};

	void updateLastInput(const std::string& input)
	{
		clearLine(coordLastInput, inputLen);
		inputLen = input.length();
		std::cout << input;
		clearLine(coordInput, inputLen);
	};

	void setReadyToInput()
	{
		SetConsoleCursorPosition(hConsole, coordInput);
	};

private:
	const int dim = 10, horSpace = 1;
	std::map<char, char> colorMap = { {'1', 'A'}, {'2', 'B'}, {'3', 'C'}, {'4', 'D'}, {'5', 'E'}, {'6', 'F'} };
	int inputLen = 0;
	int crystalStructSize = 1;
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	COORD coordZero      = { 0,  0};
	COORD coordTable     = { 3,  2};
	COORD coordInput     = { 3, 18};
	COORD coordLastInput = { 3, 21};

	void clearLine(COORD pos, const size_t& emptyLineLen)
	{
		SetConsoleCursorPosition(hConsole, pos);
		std::string emptyLine(emptyLineLen, ' ');
		std::cout << emptyLine;
		SetConsoleCursorPosition(hConsole, pos);
	};

	void updateCrystal(const int& x, const int& y, const std::string& structDump)
	{
		COORD coordCrystal = { (short)(x*(1 + horSpace) + 2 + horSpace), (short)(y + 2)};
		SetConsoleCursorPosition(hConsole, coordCrystal);
		std::cout << colorMap[getCrystalVisChar(structDump)];
	}

	char getCrystalVisChar(const std::string& dump)
	{
		// здесь разбирается та структура, что приходит из lua,
		//   и для каждого кристала подбирается буквенное обозначение
		// в данный момент никаких специальных камней нет
		return dump[0];
	}
};

#endif