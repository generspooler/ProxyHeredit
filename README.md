# ProxyHeredit

**English** | [中文](#zh)

Auto-inherit system proxy for CLI tools across **Windows, macOS, and Linux** — solves "system proxy is on but CLI tools can't reach the internet" for opencode, Claude Code, npm, Go, pip, and more.

## Problem

System proxy settings (set via OS network preferences) only work for **browsers** and a few native applications.  
CLI tools like Node.js, Go, and Python **don't read system proxy settings** — they only respect `HTTP_PROXY` / `HTTPS_PROXY` environment variables.

| Tool | System proxy on | Can connect? |
|------|----------------|-------------|
| Browser / curl | ✅ | ✅ |
| opencode / Claude Code | ❌ doesn't read OS proxy | ❌ |
| npm / yarn / pip | ❌ doesn't read OS proxy | ❌ |

## How it works

`ProxyHeredit` runs automatically on every terminal launch:

1. **Windows**: Reads system proxy from registry `HKCU:\...\Internet Settings`
2. **macOS**: Reads system proxy via `scutil --proxy`
3. **Linux**: Reads system proxy via GNOME `gsettings` or KDE `kreadconfig5`
4. Injects proxy address into `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` for the current session
5. Automatically follows when proxy is disabled or port changes — **zero maintenance**

```
OS System Proxy  ──→  profile.ps1 / profile.sh  ──→  HTTP_PROXY / HTTPS_PROXY
                      (on every terminal launch)      (visible to CLI tools)
```

## Scope

The proxy is injected into the **current terminal session** and every CLI tool launched from it (opencode, Claude Code, npm, pip, …). ProxyHeredit deliberately does **not** write permanent environment variables — those would freeze the proxy at install time and leak a stale address to non-terminal processes. GUI apps or processes started outside a terminal (Explorer/Dock-launched apps, background services) won't inherit it; point those at the OS system proxy or use TUN mode instead.

## Installation

### Windows (PowerShell)

```powershell
# Run from the project directory
.\install.ps1
```

### macOS / Linux (bash/zsh)

```bash
# Run from the project directory
chmod +x install.sh
./install.sh
```

## Verification

### Windows

```powershell
# Check if env vars are injected
$env:HTTP_PROXY
$env:HTTPS_PROXY

# Test proxy connectivity
curl.exe -s -o NUL -w "HTTP %{http_code} (%{time_total}s)" https://www.google.com
# Expected: HTTP 302 (0.3s)
```

### macOS / Linux

```bash
# Check if env vars are injected
echo "$HTTP_PROXY"
echo "$HTTPS_PROXY"

# Test proxy connectivity
curl -s -o /dev/null -w "HTTP %{http_code} (%{time_total}s)" https://www.google.com
# Expected: HTTP 302 (0.3s)
```

Verify opencode works through proxy:

```bash
opencode
```

## Uninstall

### Windows (PowerShell)

```powershell
.\uninstall.ps1
```

Manual:

```powershell
# Remove ProxyHeredit from $PROFILE, then:
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("NO_PROXY", $null, "User")
```

### macOS / Linux

```bash
./uninstall.sh
```

## Compatible Tools

Any tool that reads `HTTP_PROXY` / `HTTPS_PROXY` works automatically. Supports all platforms:

- **opencode** — AI coding assistant
- **Claude Code** — Anthropic official CLI
- **npm / yarn / pnpm** — Node.js package managers
- **Go** — `go get`, `go mod download`
- **pip** — Python package manager
- **curl / wget** — HTTP clients
- **Docker** — when `HTTP_PROXY` is configured

## Project Structure

```
ProxyHeredit/
├── README.md          # This file
├── profile.ps1        # PowerShell profile script (Windows)
├── profile.sh         # Shell profile script (macOS / Linux)
├── install.ps1        # Windows installer
├── install.sh         # macOS / Linux installer
├── uninstall.ps1      # Windows uninstaller
└── uninstall.sh       # macOS / Linux uninstaller
```

## License

MIT

---

<h2 id="zh">ProxyHeredit <span style="font-size:0.6em;font-weight:normal">中文</span></h2>

让 CLI 工具自动继承系统代理设置——支持 **Windows、macOS、Linux**，解决 opencode、Claude Code、npm、Go、pip 等工具"有系统代理但走不通"的问题。

## 问题

系统代理设置（通过 OS 网络偏好设置配置）只对**浏览器**和部分原生应用生效。  
Node.js、Go、Python 等 CLI 工具**不读取系统代理设置**，它们只认 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量。

| 工具 | 系统代理已开 | 能否联网 |
|------|------------|---------|
| 浏览器 / curl | ✅ | ✅ |
| opencode / Claude Code | ❌ 不读取系统代理 | ❌ |
| npm / yarn / pip | ❌ 不读取系统代理 | ❌ |

## 原理

`ProxyHeredit` 在每次终端启动时自动执行：

1. **Windows**: 读取注册表 `HKCU:\...\Internet Settings`
2. **macOS**: 通过 `scutil --proxy` 读取系统代理
3. **Linux**: 通过 GNOME `gsettings` 或 KDE `kreadconfig5` 读取系统代理
4. 将代理地址注入当前会话的 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 环境变量
5. 代理关闭或端口变化时自动跟随，**零维护**

```
系统代理  ──→  profile.ps1 / profile.sh  ──→  HTTP_PROXY / HTTPS_PROXY
               (每次终端启动)                 (对 CLI 工具可见)
```

## 作用范围

代理只会注入到**当前终端会话**及其中启动的 CLI 工具（opencode、Claude Code、npm、pip…）。ProxyHeredit **刻意不写永久环境变量**——那会把代理冻结在安装时刻，并向非终端进程泄漏过期地址。GUI 程序或终端外启动的进程（资源管理器/Dock 启动、后台服务）不会继承它；这类程序请走系统代理或 TUN 模式。

## 安装

### Windows (PowerShell)

```powershell
.\install.ps1
```

### macOS / Linux (bash/zsh)

```bash
chmod +x install.sh
./install.sh
```

## 验证

### Windows

```powershell
$env:HTTP_PROXY
$env:HTTPS_PROXY
curl.exe -s -o NUL -w "HTTP %{http_code} (%{time_total}s)" https://www.google.com
```

### macOS / Linux

```bash
echo "$HTTP_PROXY"
echo "$HTTPS_PROXY"
curl -s -o /dev/null -w "HTTP %{http_code} (%{time_total}s)" https://www.google.com
```

验证 opencode：

```bash
opencode
```

## 卸载

### Windows (PowerShell)

```powershell
.\uninstall.ps1
```

### macOS / Linux

```bash
./uninstall.sh
```

## 适配的工具

所有读取 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量的工具都自动生效，包括但不限于：

- **opencode** — AI 编程助手
- **Claude Code** — Anthropic 官方 CLI
- **npm / yarn / pnpm** — Node.js 包管理器
- **Go** — `go get`, `go mod download`
- **pip** — Python 包管理器
- **curl / wget** — HTTP 客户端
- **Docker** — 当配置了 `HTTP_PROXY` 时

## 项目结构

```
ProxyHeredit/
├── README.md          # 本文件
├── profile.ps1        # PowerShell 配置脚本 (Windows)
├── profile.sh         # Shell 配置脚本 (macOS / Linux)
├── install.ps1        # Windows 安装脚本
├── install.sh         # macOS / Linux 安装脚本
├── uninstall.ps1      # Windows 卸载脚本
└── uninstall.sh       # macOS / Linux 卸载脚本
```

## 许可

MIT
