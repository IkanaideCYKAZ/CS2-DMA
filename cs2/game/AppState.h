#pragma once

#include <string>
#include <vector>
#include <atomic>

// Current software version (loaded from data/version.json at runtime)
#ifdef BETA_TELEMETRY
inline std::string PROJECT_VERSION = "1.2.0-beta";  // fallback if version.json missing
#else
inline std::string PROJECT_VERSION = "1.2.0";         // fallback if version.json missing
#endif

enum class AppState {
	DMA_INITIALIZING,
	DMA_FAILED,
	SEARCHING_GAME,
	INITIALIZING_GAME,
	RUNNING,
};

namespace globalVars {
	inline float windowx = 800;
	inline float windowy = 500;
	inline std::atomic<AppState> gameState{ AppState::DMA_INITIALIZING };
}

namespace Keys {
	inline bool MenuKey = false;
	inline bool RecordKey = false;  // For grenade position recording
}
