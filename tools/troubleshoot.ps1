$OutputEncoding = [Console]::OutputEncoding = [Console]::InputEncoding = [System.Text.Encoding]::UTF8

$TOOL_DIR = Split-Path -Parent $MyInvocation.PSCommandPath
if (-not $TOOL_DIR) { $TOOL_DIR = $PSScriptRoot }
if (-not $TOOL_DIR) { $TOOL_DIR = (Get-Location).Path }

if (-not (Test-Path "$TOOL_DIR\cs2.exe")) {
    $parent = Split-Path -Parent $TOOL_DIR
    if (Test-Path "$parent\cs2.exe") { $TOOL_DIR = $parent }
}

$script:ISSUE_COUNT = 0
$script:FIXABLE_COUNT = 0
$script:FIXED_COUNT = 0

# ============================================================
#  Language strings
# ============================================================

$LANG_CN = @{
    title = "CS2-DMA 自助排障工具 v1.0"
    lang_select = "请选择语言 / Select language"
    lang_cn = "[1] 中文"
    lang_en = "[2] English"
    lang_prompt = "请输入 [1-2]"

    menu_full_diag = "一键全面诊断  - 自动检测所有常见问题"
    menu_dma = "DMA硬件检测    - 检查FPGA设备与驱动"
    menu_dep = "依赖文件检测   - 检查DLL和数据文件"
    menu_config = "配置文件检测   - 检查配置完整性"
    menu_port = "端口冲突检测   - 检查WebRadar端口"
    menu_log = "日志错误分析   - 分析最近运行日志"
    menu_report = "生成诊断报告   - 导出完整诊断信息"
    menu_fix = "一键自动修复   - 修复所有可自动修复的问题"
    menu_exit = "退出"
    menu_prompt = "请选择操作 [0-8]"

    sec_admin = "管理员权限检查"
    sec_system = "系统环境检查"
    sec_dma = "DMA硬件检测"
    sec_core_dll = "核心DLL文件检查"
    sec_dumper = "Dumper工具文件检查"
    sec_dumper_plugin = "Dumper插件检查"
    sec_data = "数据文件检查"
    sec_config = "配置目录检查"
    sec_port = "WebRadar端口检测"
    sec_log = "最近日志文件"
    sec_err_analysis = "错误分析"
    sec_game = "游戏进程检查"
    sec_main = "主程序检查"

    ok_admin = "当前以管理员权限运行"
    warn_no_admin = "未以管理员权限运行"
    hint_admin = "DMA初始化可能需要管理员权限，建议右键以管理员身份运行"

    ok_win11 = "操作系统: Windows 11 (Build {0})"
    ok_win10 = "操作系统: Windows 10 (Build {0})"
    fail_os = "不支持的操作系统版本"
    hint_os = "CS2-DMA 需要 Windows 10 或 Windows 11"
    ok_64bit = "系统架构: 64位"
    fail_32bit = "系统架构: 32位"
    hint_32bit = "CS2-DMA 需要 64位操作系统"

    ok_dma_dev = "检测到DMA设备: {0}"
    fail_dma_bad = "DMA设备存在但状态异常: {0}"
    hint_dma_bad = "设备可能需要重新安装驱动，请在设备管理器中检查"
    fail_no_dma = "未检测到DMA设备"
    hint_no_dma = "请检查: 1) FPGA设备已通过USB连接 2) 设备电源已开启 3) USB线缆正常"
    ok_ftdi_driver = "FTDI驱动已安装 (版本: {0})"
    warn_no_ftdi = "未检测到FTDI驱动"
    hint_ftdi = "请从 https://ftdichip.com/drivers/ 下载安装 D3XX 驱动"

    ok_exists = "{0} 存在"
    ok_exists_sub = "{0} 存在"
    fail_missing = "{0} 缺失"
    hint_redownload = "请重新下载完整发行版"
    warn_dumper_missing = "cs2-dumper.exe 缺失"
    hint_dumper = "DMA偏移量更新功能不可用，但不影响基本运行"
    fail_dumper_missing = "dumper\{0} 缺失"
    hint_dumper_dep = "DMA偏移量更新功能不可用，请重新下载完整发行版"
    ok_plugins = "找到 {0} 个dumper插件"
    fail_no_plugins = "dumper\plugins\ 目录为空"
    hint_plugins = "DMA偏移量更新需要memflow插件，请重新下载完整发行版"

    ok_json = "{0} 格式正常"
    fail_json_empty = "{0} 文件为空"
    hint_json = "文件已损坏，请删除后重新下载或运行偏移量更新"
    fail_json_bad = "{0} 格式异常"
    fail_json_read = "{0} 无法读取"
    hint_json_bad = "文件可能已损坏，请删除后重新下载或运行偏移量更新"
    fail_data_missing = "data\{0} 缺失"
    hint_data = "主程序无法加载{0}，请运行偏移量更新工具或重新下载"
    warn_version_missing = "data\version.json 缺失"
    hint_version = "版本检测功能不可用，但不影响基本运行"
    ok_grenade = "grenade-helper 数据目录存在"
    warn_no_grenade = "data\grenade-helper 目录缺失"
    hint_grenade = "投掷物助手功能不可用"

    ok_saved = "saved\ 配置目录存在"
    warn_no_saved = "saved\ 目录缺失"
    hint_saved = "将自动创建"
    ok_saved_created = "已自动创建 saved\ 目录"
    fail_saved = "创建 saved\ 目录失败"
    hint_saved_manual = "请手动创建 saved 文件夹"
    ok_logs = "logs\ 日志目录存在"
    warn_no_logs = "logs\ 目录缺失"
    hint_logs = "将自动创建"
    ok_logs_created = "已自动创建 logs\ 目录"
    fail_logs = "创建 logs\ 目录失败"
    hint_logs_manual = "请手动创建 logs 文件夹"
    warn_no_autosave = "_autosave.config 不存在"
    hint_autosave = "首次启动时将自动生成，不影响运行"
    warn_no_settings = "settings.json 不存在"
    hint_settings = "首次启动时将自动生成，不影响运行"

    ok_port_free = "端口 {0} 未被占用"
    fail_port_used = "端口 {0} 已被占用"
    hint_port = "占用进程: {0} (PID: {1})。解决方案: 1) 关闭占用该端口的程序 2) 在主程序中修改 WebRadar 端口"

    warn_no_log = "未找到运行日志"
    hint_no_log = "主程序可能从未运行过，或logs目录为空"
    ok_latest_log = "最新日志: {0}"
    stat_err_warn = "统计: [ERROR] {0} 个, [WARNING] {1} 个"
    more_errors = "... 还有 {0} 条错误未显示"
    fail_dma_log = "日志中检测到DMA连接失败"
    hint_dma_log = "可能原因: 1) FPGA设备未连接 2) FTD3XX驱动未安装 3) 设备被其他程序占用"
    warn_crash = "发现 {0} 个崩溃日志"
    hint_crash = "崩溃日志位于 logs\ 目录下，建议提交到 GitHub Issues"

    ok_game_running = "cs2.exe 正在运行"
    warn_no_game = "cs2.exe 未运行"
    hint_game = "主程序需要CS2游戏运行才能正常工作，请先启动游戏"

    ok_main_exists = "cs2.exe 主程序存在"
    fail_main_small = "cs2.exe 文件过小 ({0} 字节)"
    hint_main_small = "文件可能不完整，请重新下载"
    ok_main_size = "cs2.exe 文件大小: {0} MB"
    fail_no_main = "cs2.exe 主程序缺失"
    hint_main = "请重新下载完整发行版"

    diag_title = "一键全面诊断"
    diag_summary = "诊断结果汇总:"
    diag_found = "发现问题数: {0}"
    diag_fixable = "可自动修复: {0}"
    diag_fixed = "已自动修复: {0}"
    ok_no_issue = "未发现问题，主程序应该可以正常运行。"
    warn_partial_fix = "已修复部分问题，建议重新启动主程序验证。"
    fail_unfixed = "存在无法自动修复的问题，请查看上方详细说明。"
    press_enter = "按回车键返回主菜单"

    fix_title = "一键自动修复"
    fix_creating = "正在创建 {0}\ 目录..."
    fix_created = "已创建 {0}\ 目录"
    fix_create_fail = "创建 {0}\ 目录失败"
    fix_check_json = "检查损坏的配置文件..."
    fix_deleting = "删除空文件: {0}"
    fix_deleted = "已删除空文件，下次启动时将自动重新生成"
    fix_delete_fail = "删除失败"
    fix_check_port = "检查端口占用..."
    fix_port_used = "端口 22006 被进程 {0} (PID: {1}) 占用"
    fix_kill_prompt = "是否终止该进程? 输入 Y 确认"
    fix_killed = "已终止进程 {0}"
    fix_kill_fail = "终止进程失败"
    fix_applied = "已应用 {0} 项修复"
    fix_none = "没有可自动修复的问题"
    fix_manual_title = "注意: 以下问题无法自动修复，需手动处理:"
    fix_manual_dma = "- DMA硬件未连接: 请检查FPGA设备USB连接和电源"
    fix_manual_dll = "- DLL文件缺失: 请重新下载完整发行版"
    fix_manual_data = "- 数据文件缺失: 请运行偏移量更新工具或重新下载"
    fix_manual_ftdi = "- FTDI驱动未安装: 请从 ftdichip.com 下载安装"
    fix_manual_os = "- 操作系统不兼容: 需要Windows 10/11 64位"

    report_title = "生成诊断报告"
    report_collecting = "正在收集诊断信息..."
    report_header = "CS2-DMA 故障诊断报告"
    report_time = "生成时间: {0}"
    report_ok = "[OK]"
    report_missing = "[缺失]"
    report_no_ftdi = "(未检测到FTDI设备)"
    report_query_fail = "(查询失败)"
    report_no_plugins = "(无插件文件)"
    report_port_free = "端口 {0}: 未被占用"
    report_port_used = "端口 {0}: 被PID {1} 占用"
    report_game_running = "cs2.exe 正在运行 (PID: {0})"
    report_game_off = "cs2.exe 未运行"
    report_no_log = "(未找到日志文件)"
    report_no_err = "(无错误或警告)"
    report_no_crash = "(无崩溃日志)"
    report_end = "报告结束"
    report_done = "诊断报告已生成:"
    report_submit = "建议将此报告提交到 GitHub Issues 以获取帮助。"

    rpt_env = "系统环境"
    rpt_arch = "架构"
    rpt_admin = "管理员权限"
    rpt_admin_yes = "已获取管理员权限"
    rpt_admin_no = "未以管理员身份运行"
    rpt_dma = "DMA硬件"
    rpt_core = "核心文件检查"
    rpt_data = "数据文件检查"
    rpt_plugins = "Dumper插件"
    rpt_port = "端口占用"
    rpt_game = "游戏进程"
    rpt_log = "最近日志错误"
    rpt_log_file = "日志文件: {0}"
    rpt_crash = "崩溃日志列表"
}

$LANG_EN = @{
    title = "CS2-DMA Troubleshooter v1.0"
    lang_select = "请选择语言 / Select language"
    lang_cn = "[1] 中文"
    lang_en = "[2] English"
    lang_prompt = "Enter [1-2]"

    menu_full_diag = "Full Diagnostic  - Auto-detect all common issues"
    menu_dma = "DMA Hardware      - Check FPGA device & drivers"
    menu_dep = "Dependencies      - Check DLLs and data files"
    menu_config = "Configuration     - Check config integrity"
    menu_port = "Port Conflicts    - Check WebRadar ports"
    menu_log = "Log Analysis      - Analyze recent runtime logs"
    menu_report = "Diagnostic Report - Export full diagnostic info"
    menu_fix = "Auto Fix          - Fix all auto-fixable issues"
    menu_exit = "Exit"
    menu_prompt = "Select [0-8]"

    sec_admin = "Admin Privilege Check"
    sec_system = "System Environment"
    sec_dma = "DMA Hardware Detection"
    sec_core_dll = "Core DLL Files"
    sec_dumper = "Dumper Tool Files"
    sec_dumper_plugin = "Dumper Plugins"
    sec_data = "Data Files"
    sec_config = "Config Directories"
    sec_port = "WebRadar Port Detection"
    sec_log = "Recent Log Files"
    sec_err_analysis = "Error Analysis"
    sec_game = "Game Process Check"
    sec_main = "Main Program Check"

    ok_admin = "Running with administrator privileges"
    warn_no_admin = "Not running as administrator"
    hint_admin = "DMA initialization may require admin privileges. Right-click and Run as Administrator"

    ok_win11 = "OS: Windows 11 (Build {0})"
    ok_win10 = "OS: Windows 10 (Build {0})"
    fail_os = "Unsupported OS version"
    hint_os = "CS2-DMA requires Windows 10 or Windows 11"
    ok_64bit = "Architecture: 64-bit"
    fail_32bit = "Architecture: 32-bit"
    hint_32bit = "CS2-DMA requires a 64-bit OS"

    ok_dma_dev = "DMA device detected: {0}"
    fail_dma_bad = "DMA device found but abnormal: {0}"
    hint_dma_bad = "Device may need driver reinstallation. Check in Device Manager"
    fail_no_dma = "No DMA device detected"
    hint_no_dma = "Check: 1) FPGA device connected via USB 2) Device powered on 3) USB cable OK"
    ok_ftdi_driver = "FTDI driver installed (version: {0})"
    warn_no_ftdi = "FTDI driver not detected"
    hint_ftdi = "Download and install D3XX driver from https://ftdichip.com/drivers/"

    ok_exists = "{0} exists"
    ok_exists_sub = "{0} exists"
    fail_missing = "{0} missing"
    hint_redownload = "Please re-download the complete release"
    warn_dumper_missing = "cs2-dumper.exe missing"
    hint_dumper = "DMA offset update unavailable, but basic operation unaffected"
    fail_dumper_missing = "dumper\{0} missing"
    hint_dumper_dep = "DMA offset update unavailable. Please re-download the complete release"
    ok_plugins = "Found {0} dumper plugin(s)"
    fail_no_plugins = "dumper\plugins\ directory is empty"
    hint_plugins = "DMA offset update requires memflow plugins. Please re-download"

    ok_json = "{0} format OK"
    fail_json_empty = "{0} is empty"
    hint_json = "File corrupted. Delete and re-download or run offset update"
    fail_json_bad = "{0} format error"
    fail_json_read = "{0} cannot be read"
    hint_json_bad = "File may be corrupted. Delete and re-download or run offset update"
    fail_data_missing = "data\{0} missing"
    hint_data = "Cannot load {0}. Run offset update tool or re-download"
    warn_version_missing = "data\version.json missing"
    hint_version = "Version check unavailable, but basic operation unaffected"
    ok_grenade = "grenade-helper data directory exists"
    warn_no_grenade = "data\grenade-helper directory missing"
    hint_grenade = "Grenade helper unavailable"

    ok_saved = "saved\ config directory exists"
    warn_no_saved = "saved\ directory missing"
    hint_saved = "Will be created automatically"
    ok_saved_created = "Created saved\ directory"
    fail_saved = "Failed to create saved\ directory"
    hint_saved_manual = "Please manually create the saved folder"
    ok_logs = "logs\ directory exists"
    warn_no_logs = "logs\ directory missing"
    hint_logs = "Will be created automatically"
    ok_logs_created = "Created logs\ directory"
    fail_logs = "Failed to create logs\ directory"
    hint_logs_manual = "Please manually create the logs folder"
    warn_no_autosave = "_autosave.config not found"
    hint_autosave = "Will be generated on first launch, no impact"
    warn_no_settings = "settings.json not found"
    hint_settings = "Will be generated on first launch, no impact"

    ok_port_free = "Port {0} is free"
    fail_port_used = "Port {0} is in use"
    hint_port = "Used by: {0} (PID: {1}). Fix: 1) Close the process 2) Change WebRadar port in settings"

    warn_no_log = "No log files found"
    hint_no_log = "The main program may have never been run, or logs directory is empty"
    ok_latest_log = "Latest log: {0}"
    stat_err_warn = "Stats: [ERROR] {0}, [WARNING] {1}"
    more_errors = "... {0} more errors not shown"
    fail_dma_log = "DMA connection failure detected in logs"
    hint_dma_log = "Possible causes: 1) FPGA device not connected 2) FTD3XX driver not installed 3) Device in use by another process"
    warn_crash = "Found {0} crash log(s)"
    hint_crash = "Crash logs are in the logs\ directory. Submit to GitHub Issues for help"

    ok_game_running = "cs2.exe is running"
    warn_no_game = "cs2.exe is not running"
    hint_game = "The main program requires CS2 to be running. Please start the game first"

    ok_main_exists = "cs2.exe main program exists"
    fail_main_small = "cs2.exe is too small ({0} bytes)"
    hint_main_small = "File may be incomplete. Please re-download"
    ok_main_size = "cs2.exe size: {0} MB"
    fail_no_main = "cs2.exe main program missing"
    hint_main = "Please re-download the complete release"

    diag_title = "Full Diagnostic"
    diag_summary = "Diagnostic Summary:"
    diag_found = "Issues found: {0}"
    diag_fixable = "Auto-fixable: {0}"
    diag_fixed = "Auto-fixed: {0}"
    ok_no_issue = "No issues found. The main program should run normally."
    warn_partial_fix = "Some issues fixed. Restart the main program to verify."
    fail_unfixed = "Unfixable issues found. See details above."
    press_enter = "Press Enter to return to menu"

    fix_title = "Auto Fix"
    fix_creating = "Creating {0}\ directory..."
    fix_created = "Created {0}\ directory"
    fix_create_fail = "Failed to create {0}\ directory"
    fix_check_json = "Checking for corrupted config files..."
    fix_deleting = "Deleting empty file: {0}"
    fix_deleted = "Deleted empty file. Will be regenerated on next launch"
    fix_delete_fail = "Delete failed"
    fix_check_port = "Checking port conflicts..."
    fix_port_used = "Port 22006 used by {0} (PID: {1})"
    fix_kill_prompt = "Kill this process? Enter Y to confirm"
    fix_killed = "Process {0} terminated"
    fix_kill_fail = "Failed to terminate process"
    fix_applied = "{0} fix(es) applied"
    fix_none = "No auto-fixable issues found"
    fix_manual_title = "Note: The following issues require manual resolution:"
    fix_manual_dma = "- DMA hardware not connected: Check FPGA USB connection and power"
    fix_manual_dll = "- DLL files missing: Re-download the complete release"
    fix_manual_data = "- Data files missing: Run offset update tool or re-download"
    fix_manual_ftdi = "- FTDI driver not installed: Download from ftdichip.com"
    fix_manual_os = "- Incompatible OS: Requires Windows 10/11 64-bit"

    report_title = "Diagnostic Report"
    report_collecting = "Collecting diagnostic info..."
    report_header = "CS2-DMA Diagnostic Report"
    report_time = "Generated: {0}"
    report_ok = "[OK]"
    report_missing = "[MISSING]"
    report_no_ftdi = "(No FTDI device detected)"
    report_query_fail = "(Query failed)"
    report_no_plugins = "(No plugin files)"
    report_port_free = "Port {0}: Free"
    report_port_used = "Port {0}: Used by PID {1}"
    report_game_running = "cs2.exe running (PID: {0})"
    report_game_off = "cs2.exe not running"
    report_no_log = "(No log files found)"
    report_no_err = "(No errors or warnings)"
    report_no_crash = "(No crash logs)"
    report_end = "End of Report"
    report_done = "Diagnostic report generated:"
    report_submit = "Submit this report to GitHub Issues for help."

    rpt_env = "System Environment"
    rpt_arch = "Architecture"
    rpt_admin = "Admin Privileges"
    rpt_admin_yes = "Administrator privileges granted"
    rpt_admin_no = "Not running as administrator"
    rpt_dma = "DMA Hardware"
    rpt_core = "Core Files"
    rpt_data = "Data Files"
    rpt_plugins = "Dumper Plugins"
    rpt_port = "Port Usage"
    rpt_game = "Game Process"
    rpt_log = "Recent Log Errors"
    rpt_log_file = "Log file: {0}"
    rpt_crash = "Crash Logs"
}

# ============================================================
#  Language selection
# ============================================================

Clear-Host
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "   CS2-DMA Troubleshooter" -ForegroundColor White
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $($LANG_CN.lang_select)" -ForegroundColor White
Write-Host "  $($LANG_CN.lang_cn)" -ForegroundColor White
Write-Host "  $($LANG_CN.lang_en)" -ForegroundColor White
Write-Host ""
$langChoice = Read-Host "  $($LANG_CN.lang_prompt)"

if ($langChoice -eq "2") {
    $L = $LANG_EN
} else {
    $L = $LANG_CN
}

# ============================================================
#  Helper functions
# ============================================================

function Print-Section($title) {
    Write-Host ""
    Write-Host "  --- $title ---" -ForegroundColor Cyan
    Write-Host ""
}

function Print-OK($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Print-Fail($msg, $hint="") {
    Write-Host "  [XX] $msg" -ForegroundColor Red
    if ($hint) { Write-Host "    -> $hint" -ForegroundColor Yellow }
}

function Print-Warn($msg, $hint="") {
    Write-Host "  [!!] $msg" -ForegroundColor Yellow
    if ($hint) { Write-Host "    -> $hint" -ForegroundColor Yellow }
}

function Get-FileSize($path) {
    try { return (Get-Item $path -ErrorAction Stop).Length } catch { return 0 }
}

function Test-JsonValid($path, $name) {
    $size = Get-FileSize $path
    if ($size -eq 0) {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_json_empty -f $name) $L.hint_json
        return
    }
    try {
        $content = [System.IO.File]::ReadAllText($path).TrimStart()
        if ($content.StartsWith("{") -or $content.StartsWith("[")) {
            Print-OK ($L.ok_json -f $name)
        } else {
            $script:ISSUE_COUNT++
            Print-Fail ($L.fail_json_bad -f $name) $L.hint_json_bad
        }
    } catch {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_json_read -f $name) $L.hint_json_bad
    }
}

# ============================================================
#  Check Functions
# ============================================================

function Check-Admin {
    Print-Section $L.sec_admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Print-OK $L.ok_admin
    } else {
        $script:ISSUE_COUNT++
        Print-Warn $L.warn_no_admin $L.hint_admin
    }
}

function Check-SystemEnv {
    Print-Section $L.sec_system

    $osVer = [System.Environment]::OSVersion.Version
    $build = $osVer.Build
    if ($osVer.Major -eq 10 -and $build -ge 22000) {
        Print-OK ($L.ok_win11 -f $build)
    } elseif ($osVer.Major -eq 10) {
        Print-OK ($L.ok_win10 -f $build)
    } else {
        $script:ISSUE_COUNT++
        Print-Fail $L.fail_os $L.hint_os
    }

    if ([System.Environment]::Is64BitOperatingSystem) {
        Print-OK $L.ok_64bit
    } else {
        $script:ISSUE_COUNT++
        Print-Fail $L.fail_32bit $L.hint_32bit
    }
}

function Check-DMAHardware {
    Print-Section $L.sec_dma

    $ftdiDevice = $null
    try {
        $ftdiDevice = Get-PnpDevice | Where-Object {
            $_.FriendlyName -match 'FTDI|FT323H|FT232H|Future Technology|PCIe.*DMA|Screamer' -and $_.Status -eq 'OK'
        } | Select-Object -First 1
    } catch {}

    if ($ftdiDevice) {
        Print-OK ($L.ok_dma_dev -f $ftdiDevice.FriendlyName)
    } else {
        $ftdiBad = $null
        try {
            $ftdiBad = Get-PnpDevice | Where-Object {
                $_.FriendlyName -match 'FTDI|FT323H|FT232H|Future Technology' -and $_.Status -ne 'OK'
            } | Select-Object -First 1
        } catch {}

        if ($ftdiBad) {
            $script:ISSUE_COUNT++
            Print-Fail ($L.fail_dma_bad -f $ftdiBad.FriendlyName) $L.hint_dma_bad
        } else {
            $script:ISSUE_COUNT++
            Print-Fail $L.fail_no_dma $L.hint_no_dma
        }
    }

    $ftdiDriver = $null
    try {
        $ftdiDriver = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
            $_.DeviceName -match 'FTDI|Future Technology'
        } | Select-Object -First 1
    } catch {}

    if ($ftdiDriver) {
        Print-OK ($L.ok_ftdi_driver -f $ftdiDriver.DriverVersion)
    } else {
        $script:ISSUE_COUNT++
        Print-Warn $L.warn_no_ftdi $L.hint_ftdi
    }

    if (Test-Path "$TOOL_DIR\leechcore.dll") {
        Print-OK ($L.ok_exists -f "leechcore.dll")
    } elseif (Test-Path "$TOOL_DIR\dumper\leechcore.dll") {
        Print-OK ($L.ok_exists_sub -f "dumper\leechcore.dll")
    } else {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_missing -f "leechcore.dll") $L.hint_redownload
    }

    if (Test-Path "$TOOL_DIR\FTD3XX.dll") {
        Print-OK ($L.ok_exists -f "FTD3XX.dll")
    } else {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_missing -f "FTD3XX.dll") $L.hint_redownload
    }
}

function Check-DependencyFiles {
    Print-Section $L.sec_core_dll

    foreach ($dll in @("leechcore.dll", "vmm.dll", "FTD3XX.dll")) {
        if (Test-Path "$TOOL_DIR\$dll") {
            Print-OK ($L.ok_exists -f $dll)
        } else {
            $script:ISSUE_COUNT++
            Print-Fail ($L.fail_missing -f $dll) $L.hint_redownload
        }
    }

    Print-Section $L.sec_dumper

    if (Test-Path "$TOOL_DIR\dumper\cs2-dumper.exe") {
        Print-OK ($L.ok_exists -f "cs2-dumper.exe")
    } else {
        Print-Warn $L.warn_dumper_missing $L.hint_dumper
    }

    foreach ($dll in @("FTD3XXWU.dll", "leechcore.dll", "leechcore_driver.dll")) {
        if (Test-Path "$TOOL_DIR\dumper\$dll") {
            Print-OK ($L.ok_exists_sub -f "dumper\$dll")
        } else {
            $script:ISSUE_COUNT++
            Print-Fail ($L.fail_dumper_missing -f $dll) $L.hint_dumper_dep
        }
    }

    Print-Section $L.sec_dumper_plugin

    $plugins = Get-ChildItem "$TOOL_DIR\dumper\plugins\*.dll" -ErrorAction SilentlyContinue
    if ($plugins -and $plugins.Count -gt 0) {
        Print-OK ($L.ok_plugins -f $plugins.Count)
    } else {
        $script:ISSUE_COUNT++
        Print-Fail $L.fail_no_plugins $L.hint_plugins
    }
}

function Check-DataFiles {
    Print-Section $L.sec_data

    if (Test-Path "$TOOL_DIR\data\offsets.json") {
        Test-JsonValid "$TOOL_DIR\data\offsets.json" "offsets.json"
    } else {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_data_missing -f "offsets.json") ($L.hint_data -f "offsets")
    }

    if (Test-Path "$TOOL_DIR\data\client_dll.json") {
        Test-JsonValid "$TOOL_DIR\data\client_dll.json" "client_dll.json"
    } else {
        $script:ISSUE_COUNT++
        Print-Fail ($L.fail_data_missing -f "client_dll.json") ($L.hint_data -f "client offsets")
    }

    if (Test-Path "$TOOL_DIR\data\version.json") {
        Test-JsonValid "$TOOL_DIR\data\version.json" "version.json"
    } else {
        Print-Warn $L.warn_version_missing $L.hint_version
    }

    if (Test-Path "$TOOL_DIR\data\grenade-helper") {
        Print-OK $L.ok_grenade
    } else {
        Print-Warn $L.warn_no_grenade $L.hint_grenade
    }
}

function Check-ConfigFiles {
    Print-Section $L.sec_config

    if (Test-Path "$TOOL_DIR\saved") {
        Print-OK $L.ok_saved
    } else {
        $script:ISSUE_COUNT++
        $script:FIXABLE_COUNT++
        Print-Warn $L.warn_no_saved $L.hint_saved
        try { New-Item -ItemType Directory -Path "$TOOL_DIR\saved" -Force | Out-Null; $script:FIXED_COUNT++; Print-OK $L.ok_saved_created }
        catch { Print-Fail $L.fail_saved $L.hint_saved_manual }
    }

    if (Test-Path "$TOOL_DIR\logs") {
        Print-OK $L.ok_logs
    } else {
        $script:ISSUE_COUNT++
        $script:FIXABLE_COUNT++
        Print-Warn $L.warn_no_logs $L.hint_logs
        try { New-Item -ItemType Directory -Path "$TOOL_DIR\logs" -Force | Out-Null; $script:FIXED_COUNT++; Print-OK $L.ok_logs_created }
        catch { Print-Fail $L.fail_logs $L.hint_logs_manual }
    }

    if (Test-Path "$TOOL_DIR\saved\_autosave.config") {
        Test-JsonValid "$TOOL_DIR\saved\_autosave.config" "_autosave.config"
    } else {
        Print-Warn $L.warn_no_autosave $L.hint_autosave
    }

    if (Test-Path "$TOOL_DIR\settings.json") {
        Test-JsonValid "$TOOL_DIR\settings.json" "settings.json"
    } else {
        Print-Warn $L.warn_no_settings $L.hint_settings
    }
}

function Check-PortConflict {
    Print-Section $L.sec_port

    $port22006 = Get-NetTCPConnection -LocalPort 22006 -State Listen -ErrorAction SilentlyContinue
    if ($port22006) {
        $script:ISSUE_COUNT++
        $proc = Get-Process -Id $port22006[0].OwningProcess -ErrorAction SilentlyContinue
        $procName = if ($proc) { $proc.ProcessName } else { "Unknown" }
        $pid = $port22006[0].OwningProcess
        Print-Fail ($L.fail_port_used -f 22006) ($L.hint_port -f $procName, $pid)
    } else {
        Print-OK ($L.ok_port_free -f 22006)
    }

    $port22005 = Get-NetTCPConnection -LocalPort 22005 -State Listen -ErrorAction SilentlyContinue
    if ($port22005) {
        $script:ISSUE_COUNT++
        $proc = Get-Process -Id $port22005[0].OwningProcess -ErrorAction SilentlyContinue
        $procName = if ($proc) { $proc.ProcessName } else { "Unknown" }
        $pid = $port22005[0].OwningProcess
        Print-Fail ($L.fail_port_used -f 22005) ($L.hint_port -f $procName, $pid)
    } else {
        Print-OK ($L.ok_port_free -f 22005)
    }
}

function Check-LogErrors {
    Print-Section $L.sec_log

    $logFiles = Get-ChildItem "$TOOL_DIR\logs\cs2dma_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $logFiles) {
        Print-Warn $L.warn_no_log $L.hint_no_log
        return
    }

    $latestLog = $logFiles[0]
    Print-OK ($L.ok_latest_log -f $latestLog.Name)

    Print-Section $L.sec_err_analysis

    $lines = Get-Content $latestLog.FullName -ErrorAction SilentlyContinue
    $errors = $lines | Where-Object { $_ -match "ERROR" }
    $warnings = $lines | Where-Object { $_ -match "WARNING" }
    $dmaFails = $errors | Where-Object { $_ -match "DMA.*failed|InitDMA" }

    $errorCount = if ($errors) { $errors.Count } else { 0 }
    $warnCount = if ($warnings) { $warnings.Count } else { 0 }
    $dmaFailCount = if ($dmaFails) { $dmaFails.Count } else { 0 }

    $displayErrors = $errors | Select-Object -First 10
    $i = 1
    foreach ($err in $displayErrors) {
        Write-Host "    ${i}. $err" -ForegroundColor Red
        $i++
    }
    if ($errorCount -gt 10) {
        Write-Host ($L.more_errors -f ($errorCount - 10)) -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host ($L.stat_err_warn -f $errorCount, $warnCount)

    if ($dmaFailCount -gt 0) {
        Write-Host ""
        Print-Fail $L.fail_dma_log $L.hint_dma_log
    }

    $crashLogs = Get-ChildItem "$TOOL_DIR\logs\crash_*.log" -ErrorAction SilentlyContinue
    if ($crashLogs -and $crashLogs.Count -gt 0) {
        Write-Host ""
        Print-Warn ($L.warn_crash -f $crashLogs.Count) $L.hint_crash
    }
}

function Check-GameProcess {
    Print-Section $L.sec_game
    $cs2 = Get-Process -Name "cs2" -ErrorAction SilentlyContinue
    if ($cs2) {
        Print-OK $L.ok_game_running
    } else {
        Print-Warn $L.warn_no_game $L.hint_game
    }
}

function Check-MainProgram {
    Print-Section $L.sec_main
    if (Test-Path "$TOOL_DIR\cs2.exe") {
        Print-OK $L.ok_main_exists
        $size = Get-FileSize "$TOOL_DIR\cs2.exe"
        if ($size -lt 102400) {
            $script:ISSUE_COUNT++
            Print-Fail ($L.fail_main_small -f $size) $L.hint_main_small
        } else {
            $sizeMB = [math]::Round($size / 1MB)
            Print-OK ($L.ok_main_size -f $sizeMB)
        }
    } else {
        $script:ISSUE_COUNT++
        Print-Fail $L.fail_no_main $L.hint_main
    }
}

# ============================================================
#  Full Diagnostic
# ============================================================

function Run-FullDiag {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host "   $($L.diag_title)" -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host ""

    $script:ISSUE_COUNT = 0
    $script:FIXABLE_COUNT = 0
    $script:FIXED_COUNT = 0

    Check-Admin
    Check-SystemEnv
    Check-DMAHardware
    Check-DependencyFiles
    Check-DataFiles
    Check-ConfigFiles
    Check-PortConflict
    Check-GameProcess
    Check-MainProgram

    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  $($L.diag_summary)" -ForegroundColor White
    Write-Host ""
    Write-Host "  $($L.diag_found -f $script:ISSUE_COUNT)"
    Write-Host "  $($L.diag_fixable -f $script:FIXABLE_COUNT)"
    Write-Host "  $($L.diag_fixed -f $script:FIXED_COUNT)"
    Write-Host ""

    if ($script:ISSUE_COUNT -eq 0) {
        Print-OK $L.ok_no_issue
    } elseif ($script:FIXED_COUNT -gt 0) {
        Print-Warn $L.warn_partial_fix
    } else {
        Print-Fail $L.fail_unfixed
    }

    Write-Host ""
    Read-Host "  $($L.press_enter)"
}

# ============================================================
#  Auto Fix
# ============================================================

function Run-AutoFix {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host "   $($L.fix_title)" -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host ""

    $fixApplied = 0

    foreach ($dir in @("saved", "logs", "data", "data\grenade-helper")) {
        $fullPath = Join-Path $TOOL_DIR $dir
        if (-not (Test-Path $fullPath)) {
            Write-Host "  [..] $($L.fix_creating -f $dir)" -ForegroundColor Yellow
            try {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                Write-Host "  [OK] $($L.fix_created -f $dir)" -ForegroundColor Green
                $fixApplied++
            } catch {
                Write-Host "  [XX] $($L.fix_create_fail -f $dir)" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "  [..] $($L.fix_check_json)" -ForegroundColor Yellow

    foreach ($jf in @("$TOOL_DIR\data\offsets.json", "$TOOL_DIR\data\client_dll.json", "$TOOL_DIR\data\version.json", "$TOOL_DIR\saved\_autosave.config")) {
        if ((Test-Path $jf) -and (Get-FileSize $jf) -eq 0) {
            Write-Host "  [..] $($L.fix_deleting -f $jf)" -ForegroundColor Yellow
            try {
                Remove-Item $jf -Force
                Write-Host "  [OK] $($L.fix_deleted)" -ForegroundColor Green
                $fixApplied++
            } catch {
                Write-Host "  [XX] $($L.fix_delete_fail)" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "  [..] $($L.fix_check_port)" -ForegroundColor Yellow
    $portConn = Get-NetTCPConnection -LocalPort 22006 -State Listen -ErrorAction SilentlyContinue
    if ($portConn) {
        $pid = $portConn[0].OwningProcess
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        $procName = if ($proc) { $proc.ProcessName } else { "Unknown" }
        Write-Host "  [!!] $($L.fix_port_used -f $procName, $pid)" -ForegroundColor Yellow
        $answer = Read-Host "       $($L.fix_kill_prompt)"
        if ($answer -eq "Y" -or $answer -eq "y") {
            try { Stop-Process -Id $pid -Force; Write-Host "  [OK] $($L.fix_killed -f $pid)" -ForegroundColor Green; $fixApplied++ }
            catch { Write-Host "  [XX] $($L.fix_kill_fail)" -ForegroundColor Red }
        }
    }

    Write-Host ""
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    if ($fixApplied -gt 0) {
        Write-Host "  [OK] $($L.fix_applied -f $fixApplied)" -ForegroundColor Green
    } else {
        Write-Host "  [--] $($L.fix_none)" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "  $($L.fix_manual_title)" -ForegroundColor DarkGray
    Write-Host "  $($L.fix_manual_dma)" -ForegroundColor DarkGray
    Write-Host "  $($L.fix_manual_dll)" -ForegroundColor DarkGray
    Write-Host "  $($L.fix_manual_data)" -ForegroundColor DarkGray
    Write-Host "  $($L.fix_manual_ftdi)" -ForegroundColor DarkGray
    Write-Host "  $($L.fix_manual_os)" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  $($L.press_enter)"
}

# ============================================================
#  Generate Report
# ============================================================

function Run-GenReport {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host "   $($L.report_title)" -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host ""
    Write-Host "  $($L.report_collecting)" -ForegroundColor Yellow

    if (-not (Test-Path "$TOOL_DIR\logs")) {
        New-Item -ItemType Directory -Path "$TOOL_DIR\logs" -Force | Out-Null
    }

    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$TOOL_DIR\logs\diagnostic_report_$ts.txt"

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("============================================================")
    [void]$sb.AppendLine("  $($L.report_header)")
    [void]$sb.AppendLine("  $($L.report_time -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))")
    [void]$sb.AppendLine("============================================================")
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_env)]")
    [void]$sb.AppendLine("OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption) Build $([System.Environment]::OSVersion.Version.Build)")
    [void]$sb.AppendLine("$($L.rpt_arch): $(if([System.Environment]::Is64BitOperatingSystem){'64-bit'}else{'32-bit'})")
    try { [void]$sb.AppendLine("CPU: $(Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)") } catch {}
    try { [void]$sb.AppendLine("GPU: $(Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name)") } catch {}
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_admin)]")
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    [void]$sb.AppendLine("$(if($isAdmin){$L.rpt_admin_yes}else{$L.rpt_admin_no})")
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_dma)]")
    try {
        $ftdiDevs = Get-PnpDevice | Where-Object { $_.FriendlyName -match 'FTDI|FT323H|FT232H|Future Technology' }
        if ($ftdiDevs) { $ftdiDevs | ForEach-Object { [void]$sb.AppendLine("  $($_.Status) | $($_.Class) | $($_.FriendlyName)") } }
        else { [void]$sb.AppendLine("  $($L.report_no_ftdi)") }
    } catch { [void]$sb.AppendLine("  $($L.report_query_fail)") }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_core)]")
    foreach ($f in @("cs2.exe", "leechcore.dll", "vmm.dll", "FTD3XX.dll")) {
        [void]$sb.AppendLine("$(if(Test-Path "$TOOL_DIR\$f"){$L.report_ok}else{$L.report_missing}) $f")
    }
    [void]$sb.AppendLine("")
    foreach ($f in @("dumper\cs2-dumper.exe", "dumper\FTD3XXWU.dll", "dumper\leechcore.dll", "dumper\leechcore_driver.dll")) {
        [void]$sb.AppendLine("$(if(Test-Path "$TOOL_DIR\$f"){$L.report_ok}else{$L.report_missing}) $f")
    }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_data)]")
    foreach ($f in @("data\offsets.json", "data\client_dll.json", "data\version.json")) {
        $fullPath = "$TOOL_DIR\$f"
        if (Test-Path $fullPath) {
            $sz = (Get-Item $fullPath).Length
            [void]$sb.AppendLine("$($L.report_ok) $f ($sz bytes)")
        } else {
            [void]$sb.AppendLine("$($L.report_missing) $f")
        }
    }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_plugins)]")
    $plugins = Get-ChildItem "$TOOL_DIR\dumper\plugins\*.dll" -ErrorAction SilentlyContinue
    if ($plugins) { $plugins | ForEach-Object { [void]$sb.AppendLine("  $($_.Name)") } }
    else { [void]$sb.AppendLine("  $($L.report_no_plugins)") }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_port)]")
    $p22006 = Get-NetTCPConnection -LocalPort 22006 -State Listen -ErrorAction SilentlyContinue
    if ($p22006) { [void]$sb.AppendLine("  $($L.report_port_used -f 22006, $p22006[0].OwningProcess)") }
    else { [void]$sb.AppendLine("  $($L.report_port_free -f 22006)") }
    $p22005 = Get-NetTCPConnection -LocalPort 22005 -State Listen -ErrorAction SilentlyContinue
    if ($p22005) { [void]$sb.AppendLine("  $($L.report_port_used -f 22005, $p22005[0].OwningProcess)") }
    else { [void]$sb.AppendLine("  $($L.report_port_free -f 22005)") }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_game)]")
    $cs2proc = Get-Process -Name "cs2" -ErrorAction SilentlyContinue
    if ($cs2proc) { [void]$sb.AppendLine("  $($L.report_game_running -f $cs2proc.Id)") }
    else { [void]$sb.AppendLine("  $($L.report_game_off)") }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_log)]")
    $logFiles = Get-ChildItem "$TOOL_DIR\logs\cs2dma_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($logFiles) {
        [void]$sb.AppendLine("  $($L.rpt_log_file -f $logFiles[0].Name)")
        [void]$sb.AppendLine("")
        $errLines = Get-Content $logFiles[0].FullName -ErrorAction SilentlyContinue | Where-Object { $_ -match "ERROR|WARNING" }
        if ($errLines) { $errLines | ForEach-Object { [void]$sb.AppendLine("  $_") } }
        else { [void]$sb.AppendLine("  $($L.report_no_err)") }
    } else {
        [void]$sb.AppendLine("  $($L.report_no_log)")
    }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("[$($L.rpt_crash)]")
    $crashLogs = Get-ChildItem "$TOOL_DIR\logs\crash_*.log" -ErrorAction SilentlyContinue
    if ($crashLogs) { $crashLogs | ForEach-Object { [void]$sb.AppendLine("  $($_.Name)") } }
    else { [void]$sb.AppendLine("  $($L.report_no_crash)") }
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("============================================================")
    [void]$sb.AppendLine("  $($L.report_end)")
    [void]$sb.AppendLine("============================================================")

    [System.IO.File]::WriteAllText($reportFile, $sb.ToString(), [System.Text.Encoding]::UTF8)

    Write-Host ""
    Write-Host "  [OK] $($L.report_done)" -ForegroundColor Green
    Write-Host "  $reportFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  $($L.report_submit)"
    Write-Host ""
    Read-Host "  $($L.press_enter)"
}

function Show-SectionPage($title, [scriptblock]$checks) {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host "   $title" -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor White
    Write-Host ""
    & $checks
    Write-Host ""
    Read-Host "  $($L.press_enter)"
}

# ============================================================
#  Main Menu
# ============================================================

while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host "   $($L.title)" -ForegroundColor White
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] $($L.menu_full_diag)" -ForegroundColor White
    Write-Host "  [2] $($L.menu_dma)" -ForegroundColor White
    Write-Host "  [3] $($L.menu_dep)" -ForegroundColor White
    Write-Host "  [4] $($L.menu_config)" -ForegroundColor White
    Write-Host "  [5] $($L.menu_port)" -ForegroundColor White
    Write-Host "  [6] $($L.menu_log)" -ForegroundColor White
    Write-Host "  [7] $($L.menu_report)" -ForegroundColor White
    Write-Host "  [8] $($L.menu_fix)" -ForegroundColor White
    Write-Host "  [0] $($L.menu_exit)" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  $($L.menu_prompt)"

    switch ($choice) {
        "1" { Run-FullDiag }
        "2" { Show-SectionPage $L.sec_dma { Check-DMAHardware } }
        "3" { Show-SectionPage $L.menu_dep { Check-DependencyFiles; Check-DataFiles } }
        "4" { Show-SectionPage $L.menu_config { Check-ConfigFiles } }
        "5" { Show-SectionPage $L.menu_port { Check-PortConflict } }
        "6" { Show-SectionPage $L.menu_log { Check-LogErrors } }
        "7" { Run-GenReport }
        "8" { Run-AutoFix }
        "0" { exit 0 }
    }
}
