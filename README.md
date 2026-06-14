# ProxyHeredit

让 CLI 工具自动继承系统代理设置——解决 opencode、Claude Code、npm、Go、pip 等工具"有系统代理但走不通"的问题。

## 问题

Windows 的系统代理（Internet Options → 连接 → 局域网设置）只对**浏览器**和部分原生应用生效。  
Node.js、Go、Python 等 CLI 工具**不读取注册表代理设置**，它们只认 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量。

结果：

| 工具 | 系统代理已开 | 能否联网 |
|---|---|---|
| 浏览器 / curl | ✅ | ✅ |
| opencode / Claude Code | ❌ 不读取注册表 | ❌ |
| npm / yarn / pip | ❌ 不读取注册表 | ❌ |

## 原理

`ProxyHeredit` 在 PowerShell 启动时自动执行：

1. 读取注册表 `HKCU:\...\Internet Settings` 中的系统代理配置
2. 将代理地址注入当前会话的 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 环境变量
3. 代理关闭或端口变化时自动跟随，**零维护**

```
注册表 (系统代理)  ──→  profile.ps1  ──→  $env:HTTP_PROXY / HTTPS_PROXY
                      (每次终端启动)         (对 CLI 工具可见)
```

## 安装

```powershell
# 从项目目录执行
.\install.ps1
```


## 验证

```powershell
# 检查环境变量是否注入
$env:HTTP_PROXY
$env:HTTPS_PROXY

# 测试代理连通性
curl.exe -s -o NUL -w "HTTP %{http_code} (%{time_total}s)" https://www.google.com
# 期望输出: HTTP 302 (0.3s)
```

验证 opencode 走代理：

```powershell
# 确认 opencode 能正常访问外部 API
opencode
```

## 卸载

```powershell
# 从项目目录执行
.\uninstall.ps1
```

手动卸载：

```powershell
# 1. 从 Profile 中移除 ProxyHeredit 代码
$profileContent = Get-Content $PROFILE -Raw
$profileContent = $profileContent -replace '(?s)# ==+[\s\S]*?# ==+.*?(?=\n# ==|\Z)', ''
Set-Content $PROFILE $profileContent -Encoding UTF8

# 2. 删除 User 级环境变量
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $null, "User")
[System.Environment]::SetEnvironmentVariable("NO_PROXY", $null, "User")
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
├── profile.ps1        # 核心 PowerShell Profile 脚本
├── install.ps1        # 一键安装
└── uninstall.ps1      # 一键卸载
```

## 许可

MIT
