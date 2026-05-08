#pragma once

#include <string>

#include <iostream>

class SettingsManager
{
public:
	std::string language; // empty = auto-detect from system UI language

	void LoadSettings();
};

inline SettingsManager settingsJson;
