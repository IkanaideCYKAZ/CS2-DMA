#include "Telemetry.h"

#ifdef BETA_TELEMETRY

#include "Logger.h"
#include "base64.h"

#include <string>
#include <fstream>
#include <sstream>
#include <mutex>
#include <chrono>
#include <thread>
#include <cstring>
#include <cstdio>
#include <filesystem>
#include <vector>
#include <algorithm>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winhttp.h>

#pragma comment(lib, "winhttp.lib")

// =====================================================================
//  PAT token — loaded from TelemetryToken.h (gitignored, not in repo)
// =====================================================================
#include "TelemetryToken.h"

// =====================================================================
//  Internal state
// =====================================================================
static std::mutex  g_TelMutex;
static std::string g_LogFilePath;
static std::string g_CrashLogPath;
static std::string g_CrashDmpPath;
static bool        g_Initialized = false;

// =====================================================================
//  GitHub repo config
// =====================================================================
static const wchar_t* GH_API_HOST  = L"api.github.com";
static const char*    GH_REPO      = "chao-shushu/card";
static const char*    GH_BRANCH    = "main";

// =====================================================================
//  Helpers
// =====================================================================
static std::string GetComputerName()
{
    char buf[256] = {};
    DWORD size = sizeof(buf);
    if (GetComputerNameA(buf, &size))
        return std::string(buf);
    return "unknown";
}

static std::string MakeRemotePath(const std::string& filename)
{
    // telemetry/YYYY/MM/DD/filename
    auto now = std::chrono::system_clock::now();
    auto t   = std::chrono::system_clock::to_time_t(now);
    struct tm ti{};
    localtime_s(&ti, &t);

    char path[256];
    snprintf(path, sizeof(path), "telemetry/%04d/%02d/%02d/%s",
             ti.tm_year + 1900, ti.tm_mon + 1, ti.tm_mday, filename.c_str());
    return path;
}

static std::string ExtractFilename(const std::string& path)
{
    size_t pos = path.find_last_of("/\\");
    return (pos != std::string::npos) ? path.substr(pos + 1) : path;
}

static bool ReadFileContent(const std::string& path, std::string& out)
{
    std::ifstream f(path, std::ios::binary);
    if (!f.is_open()) return false;
    std::ostringstream ss;
    ss << f.rdbuf();
    out = ss.str();
    return true;
}

// =====================================================================
//  GitHub Contents API — GET file SHA (needed for updating existing files)
// =====================================================================
static std::string GetFileSha(const std::string& remotePath)
{
    std::string apiPathStr = "/repos/" + std::string(GH_REPO) + "/contents/" + remotePath;
    std::wstring apiPath(apiPathStr.begin(), apiPathStr.end());

    std::string authStr = "token " + std::string(GH_TOKEN);
    std::wstring authHeader(authStr.begin(), authStr.end());

    HINTERNET hSession = WinHttpOpen(L"CS2-DMA-Telemetry/1.0",
                                     WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                                     WINHTTP_NO_PROXY_NAME,
                                     WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) return "";

    HINTERNET hConnect = WinHttpConnect(hSession, GH_API_HOST,
                                        INTERNET_DEFAULT_HTTPS_PORT, 0);
    if (!hConnect) { WinHttpCloseHandle(hSession); return ""; }

    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"GET", apiPath.c_str(),
                                            NULL, WINHTTP_NO_REFERER,
                                            WINHTTP_DEFAULT_ACCEPT_TYPES,
                                            WINHTTP_FLAG_SECURE);
    if (!hRequest) { WinHttpCloseHandle(hConnect); WinHttpCloseHandle(hSession); return ""; }

    DWORD timeout = 5000;
    WinHttpSetOption(hRequest, WINHTTP_OPTION_CONNECT_TIMEOUT, &timeout, sizeof(timeout));
    WinHttpSetOption(hRequest, WINHTTP_OPTION_RECEIVE_TIMEOUT, &timeout, sizeof(timeout));

    std::wstring authLine = L"Authorization: " + authHeader;
    WinHttpAddRequestHeaders(hRequest, authLine.c_str(), (DWORD)authLine.size(), WINHTTP_ADDREQ_FLAG_ADD);

    if (!WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                            WINHTTP_NO_REQUEST_DATA, 0, 0, 0) ||
        !WinHttpReceiveResponse(hRequest, NULL)) {
        WinHttpCloseHandle(hRequest); WinHttpCloseHandle(hConnect); WinHttpCloseHandle(hSession);
        return "";
    }

    DWORD statusCode = 0, sz = sizeof(statusCode);
    WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        NULL, &statusCode, &sz, NULL);

    std::string response;
    if (statusCode == 200) {
        char buffer[4096];
        DWORD bytesRead = 0;
        while (WinHttpReadData(hRequest, buffer, sizeof(buffer), &bytesRead) && bytesRead > 0) {
            response.append(buffer, bytesRead);
            bytesRead = 0;
        }
    }

    WinHttpCloseHandle(hRequest); WinHttpCloseHandle(hConnect); WinHttpCloseHandle(hSession);

    if (statusCode != 200 || response.empty()) return "";

    // Extract "sha":"..." from JSON (simple string search, no JSON library needed)
    const std::string needle = "\"sha\"";
    size_t pos = response.find(needle);
    if (pos == std::string::npos) return "";
    pos = response.find('"', pos + needle.size());
    if (pos == std::string::npos) return "";
    size_t end = response.find('"', pos + 1);
    if (end == std::string::npos) return "";
    return response.substr(pos + 1, end - pos - 1);
}

// =====================================================================
//  GitHub Contents API upload (PUT)
// =====================================================================
static bool UploadToGitHub(const std::string& remotePath, const std::string& filename,
                           const std::string& contentBase64)
{
    // Check if file already exists — if so, we need its SHA for the update
    std::string existingSha = GetFileSha(remotePath);

    // Build JSON body: {"message":"...","branch":"main","content":"base64...","sha":"..."}
    std::string commitMsg = "telemetry: upload " + filename;
    std::string body = "{\"message\":\"" + commitMsg + "\","
                       "\"branch\":\"" + GH_BRANCH + "\","
                       "\"content\":\"" + contentBase64 + "\"";
    if (!existingSha.empty()) {
        body += ",\"sha\":\"" + existingSha + "\"";
    }
    body += "}";

    // Build API path: /repos/{owner}/{repo}/contents/{path}
    std::string apiPathStr = "/repos/" + std::string(GH_REPO) + "/contents/" + remotePath;
    std::wstring apiPath(apiPathStr.begin(), apiPathStr.end());

    // Build Authorization header
    std::string authStr = "token " + std::string(GH_TOKEN);
    std::wstring authHeader(authStr.begin(), authStr.end());

    HINTERNET hSession = WinHttpOpen(L"CS2-DMA-Telemetry/1.0",
                                     WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
                                     WINHTTP_NO_PROXY_NAME,
                                     WINHTTP_NO_PROXY_BYPASS, 0);
    if (!hSession) {
        return false;
    }

    HINTERNET hConnect = WinHttpConnect(hSession, GH_API_HOST,
                                        INTERNET_DEFAULT_HTTPS_PORT, 0);
    if (!hConnect) {
        WinHttpCloseHandle(hSession);
        return false;
    }

    HINTERNET hRequest = WinHttpOpenRequest(hConnect, L"PUT", apiPath.c_str(),
                                            NULL, WINHTTP_NO_REFERER,
                                            WINHTTP_DEFAULT_ACCEPT_TYPES,
                                            WINHTTP_FLAG_SECURE);
    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Timeouts
    DWORD connectTimeout = 5000;
    DWORD receiveTimeout = 10000;
    WinHttpSetOption(hRequest, WINHTTP_OPTION_CONNECT_TIMEOUT, &connectTimeout, sizeof(connectTimeout));
    WinHttpSetOption(hRequest, WINHTTP_OPTION_RECEIVE_TIMEOUT, &receiveTimeout, sizeof(receiveTimeout));

    // Set headers
    std::wstring authLine = L"Authorization: " + authHeader;
    WinHttpAddRequestHeaders(hRequest, authLine.c_str(), (DWORD)authLine.size(), WINHTTP_ADDREQ_FLAG_ADD);

    // Send request with body
    BOOL ok = WinHttpSendRequest(hRequest,
                                 L"Content-Type: application/json",
                                 (DWORD)-1,
                                 (LPVOID)body.c_str(),
                                 (DWORD)body.size(),
                                 (DWORD)body.size(),
                                 0);
    if (!ok) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Receive response
    if (!WinHttpReceiveResponse(hRequest, NULL)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        return false;
    }

    // Check status code
    DWORD statusCode = 0, size = sizeof(statusCode);
    WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
                        NULL, &statusCode, &size, NULL);

    // Read response body (for logging)
    std::string response;
    {
        char buffer[4096];
        DWORD bytesRead = 0;
        while (WinHttpReadData(hRequest, buffer, sizeof(buffer), &bytesRead) && bytesRead > 0) {
            response.append(buffer, bytesRead);
            bytesRead = 0;
        }
    }

    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    if (statusCode == 201 || statusCode == 200) {
        return true;
    } else {
        return false;
    }
}

// Sanitize content: remove secrets before uploading to prevent GitHub secret scanning revocation
static void SanitizeContent(std::string& content)
{
    const std::string token(GH_TOKEN);
    if (token.empty()) return;
    const std::string redacted = "[REDACTED]";
    size_t pos = 0;
    while ((pos = content.find(token, pos)) != std::string::npos) {
        content.replace(pos, token.size(), redacted);
        pos += redacted.size();
    }
}

// Upload a local file to GitHub
static bool UploadFile(const std::string& localPath)
{
    std::string content;
    if (!ReadFileContent(localPath, content)) {
        return false;
    }

    // Remove secrets before uploading
    SanitizeContent(content);

    // GitHub API requires base64-encoded content
    std::string b64 = base64::to_base64(std::string_view(content));

    std::string filename = ExtractFilename(localPath);
    std::string remotePath = MakeRemotePath(filename);

    return UploadToGitHub(remotePath, filename, b64);
}

// =====================================================================
//  Public API
// =====================================================================
void Telemetry::Init()
{
    std::lock_guard<std::mutex> lock(g_TelMutex);
    g_Initialized = true;

    // Upload previous session logs asynchronously to avoid blocking startup
    std::thread([]() { UploadPreviousLogs(); }).detach();
}

void Telemetry::UploadPreviousLogs()
{
    namespace fs = std::filesystem;
    std::string logDir = "logs";
    if (!fs::exists(logDir)) return;

    std::string currentLogFilename;
    if (!g_LogFilePath.empty()) {
        currentLogFilename = ExtractFilename(g_LogFilePath);
    }

    // Collect previous .log and .dmp files (skip current session)
    std::vector<std::string> filesToUpload;
    for (const auto& entry : fs::directory_iterator(logDir)) {
        if (!entry.is_regular_file()) continue;
        std::string name = entry.path().filename().string();
        // Skip current session log
        if (name == currentLogFilename) continue;
        // Only upload .log and .dmp files
        if (name.size() >= 5 && (name.substr(name.size() - 4) == ".log" || name.substr(name.size() - 4) == ".dmp")) {
            filesToUpload.push_back(entry.path().string());
        }
    }

    // Sort by name (timestamp-based) and upload the most recent ones
    std::sort(filesToUpload.rbegin(), filesToUpload.rend());
    int uploaded = 0;
    for (const auto& file : filesToUpload) {
        // Skip .dmp files larger than 5MB
        if (file.size() >= 4 && file.substr(file.size() - 4) == ".dmp") {
            std::ifstream f(file, std::ios::binary | std::ios::ate);
            if (f.is_open() && f.tellg() > 5 * 1024 * 1024) continue;
        }
        if (UploadFile(file)) {
            uploaded++;
            // Delete after successful upload to avoid re-uploading
            std::error_code ec;
            fs::remove(file, ec);
        }
        // Only upload up to 10 files to avoid blocking startup too long
        if (uploaded >= 10) break;
    }
}

void Telemetry::SetLogFilePath(const std::string& path)
{
    std::lock_guard<std::mutex> lock(g_TelMutex);
    g_LogFilePath = path;
}

void Telemetry::SetCrashFiles(const std::string& logPath, const std::string& dmpPath)
{
    std::lock_guard<std::mutex> lock(g_TelMutex);
    g_CrashLogPath = logPath;
    g_CrashDmpPath = dmpPath;
}

void Telemetry::UploadSessionLog()
{
    std::lock_guard<std::mutex> lock(g_TelMutex);
    if (!g_Initialized || g_LogFilePath.empty()) return;

    UploadFile(g_LogFilePath);
}

void Telemetry::UploadCrashFiles()
{
    std::lock_guard<std::mutex> lock(g_TelMutex);
    if (!g_Initialized) return;

    if (!g_CrashLogPath.empty()) {
        UploadFile(g_CrashLogPath);
    }
    if (!g_CrashDmpPath.empty()) {
        // MiniDump files can be large (>10MB), skip if too big for GitHub API
        std::ifstream f(g_CrashDmpPath, std::ios::binary | std::ios::ate);
        if (f.is_open()) {
            auto size = f.tellg();
            if (size <= 5 * 1024 * 1024) { // 5MB limit
                UploadFile(g_CrashDmpPath);
            }
        }
    }
    // Also upload the session log alongside crash files
    if (!g_LogFilePath.empty()) {
        UploadFile(g_LogFilePath);
    }
}

#else // !BETA_TELEMETRY — all no-ops

void Telemetry::Init() {}
void Telemetry::UploadPreviousLogs() {}
void Telemetry::SetLogFilePath(const std::string&) {}
void Telemetry::SetCrashFiles(const std::string&, const std::string&) {}
void Telemetry::UploadSessionLog() {}
void Telemetry::UploadCrashFiles() {}

#endif // BETA_TELEMETRY
