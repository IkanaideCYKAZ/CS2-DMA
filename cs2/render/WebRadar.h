#pragma once

#include <string>
#include <vector>
#include <mutex>
#include <thread>
#include <atomic>
#include <cstdint>

// Forward-declare SOCKET to avoid including winsock2.h here
// (winsock2.h must come before windows.h; GUI.cpp includes windows.h first)
#ifndef _WINSOCK2API_
typedef unsigned __int64 SOCKET;
#define INVALID_SOCKET (SOCKET)(~0)
#endif

// Lightweight WebSocket server for Web Radar (RFC 6455)
// Zero external dependencies — uses only Winsock2 (already linked).
// Binds to 0.0.0.0 so any LAN device can connect.
class WebRadarServer {
public:
	WebRadarServer() = default;
	~WebRadarServer();

	WebRadarServer(const WebRadarServer&) = delete;
	WebRadarServer& operator=(const WebRadarServer&) = delete;

	bool Start(uint16_t port);
	void Stop();

	// Send a message to all connected WebSocket clients.
	// Thread-safe — can be called from any thread.
	void Broadcast(const std::string& message);

	bool IsRunning() const { return m_running.load(); }
	int  GetClientCount() const;

private:
	void AcceptLoop();
	void ClientLoop(SOCKET clientSock);
	bool DoHandshake(SOCKET clientSock);
	bool DoHandshakeWithRequest(SOCKET clientSock, const std::string& request);
	bool SendFrame(SOCKET sock, const std::string& payload);
	void RemoveClient(SOCKET sock);

	SOCKET m_listenSock = INVALID_SOCKET;
	std::atomic<bool> m_running{ false };
	std::thread m_acceptThread;

	mutable std::mutex m_clientsMutex;
	std::vector<SOCKET> m_clients;
};

// Global state exposed for GUI (updated by WebRadarThread)
inline std::atomic<int> g_webRadarClientCount{ 0 };
inline std::atomic<bool> g_webRadarRunning{ false };

// Cloudflare tunnel state (updated by Start/StopCloudflareTunnel)
inline std::atomic<bool> g_cloudflareTunnelRunning{ false };
inline std::string g_cloudflareTunnelURL;   // guarded by g_cloudflareTunnelMutex
inline std::mutex g_cloudflareTunnelMutex;

// Installation state for cloudflared auto-install
enum class CfInstallState {
	None,           // no install in progress
	Installing,     // winget install running
	Success,        // installed successfully
	Failed,         // installation failed
};
inline std::atomic<CfInstallState> g_cfInstallState{ CfInstallState::None };

// Get first LAN IPv4 address of this machine (for GUI display).
// Returns empty string on failure. Implemented in WebRadar.cpp.
std::string GetLocalIP();

// Cloudflare tunnel management (implemented in WebRadar.cpp)
// Starts cloudflared quick tunnel pointing at the given port.
// If cloudflared not found, auto-installs via winget, then starts.
// Returns false only if install fails. URL is captured asynchronously.
bool StartCloudflareTunnel(int port);
void StopCloudflareTunnel();

// Thread function — reads GameSnapshot, serializes to JSON, broadcasts via WebSocket.
// Declared here, implemented in WebRadar.cpp, started from main.cpp alongside other threads.
VOID WebRadarThread();
