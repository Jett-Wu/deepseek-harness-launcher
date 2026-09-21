<p align="center">
  <a href="#english">🇬🇧 English</a> · <a href="#chinese">🇨🇳 中文</a>
</p>

<h1 align="center" id="english">🚀 DeepSeek Harness Launcher</h1>

<p align="center">
  <a href="#license"><img alt="License" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
  <a href="#"><img alt="Platform" src="https://img.shields.io/badge/Windows-10%2F11-0078D6.svg"></a>
  <a href="#"><img alt="Source" src="https://img.shields.io/badge/package-official%20npm-brightgreen.svg"></a>
  <br>
  <b>Download &amp; run · Official package only · Zero config · No third-party code</b>
</p>

> Double-click `start-dsh.bat` and it sets everything up, then opens the <a href="https://www.npmjs.com/package/@deepseek-ai/dsh">DeepSeek Harness</a> web UI.
> No third-party desktop wrappers — it installs and runs the official npm package directly: safe, stable, and always up to date.

## ✨ Features

- 🪄 **Zero friction**: no Node.js? it auto-installs via winget; the first run installs the official package, then launches in seconds
- ⚡ **Fast**: ~1 second to launch after the first install; never starts a second instance if already running
- 🔄 **Update notice**: every time you open the menu it shows your version next to the latest one on npm, and never installs anything behind your back
- 💾 **Optional backup**: if a `dsh-backup` helper sits next to this script (or `DSH_BACKUP_PS1` points at one), menu option 3 backs up sessions and plugins
- 🛡️ **Clean &amp; safe**: installs only `@deepseek-ai/dsh` from the official npm registry — no third-party binaries, no data collection
- 🌍 **Universal**: pure-ASCII script, runs on any language edition of Windows 10/11
- 🚄 **China mirror**: switches npm to the npmmirror registry for fast installs in China, auto-falls back to the official registry
- 🛠️ **Self-healing**: if an update fails or Node.js is upgraded, the next launch rebuilds the local install automatically

## 🚀 Quick Start

1. Download `start-dsh.bat`
2. Double-click it and press `1` - no Enter needed
3. The first run auto-installs everything (needs internet, ~1–3 min), then opens `http://127.0.0.1:3080`

That's it — every launch after that is one click.

> Tip: pin `start-dsh.bat` to the taskbar or send a desktop shortcut for daily use.

## 📖 Usage

Double-click `start-dsh.bat` for a menu - press a number key, no Enter needed.

> The first time you use Backup it asks where backups should be stored and remembers your answer.

| Menu | Action | Command line |
|---|---|---|
| 1 | Start DSH (default) | `start-dsh.bat start` |
| 2 | Update to the latest release | `start-dsh.bat update` |
| 3 | Back up sessions and plugins | `start-dsh.bat backup` |
| 4 | Diagnose, with optional repair | `start-dsh.bat diagnose` |
| 5 | Uninstall | `start-dsh.bat uninstall` |

## 🧩 Recommended Plugins

Community-recommended plugins (not officially maintained - install one at a time and check each repo's issues before relying on them):

| Plugin | What it does |
|---|---|
| `@linxin666/dsh-web-all` | All-in-one Web UI bundle: task board, git graph, right-side panel (files/terminal/browser), skin center |
| `@liustack/modsearch` | Adds web search, X search and page fetch to models without web access - free, no API key, automatic engine failover |
| `dsh-ego-browser` | Gives the agent a built-in browser: semantic clicks, form filling, screenshots |
| `@kingOfSoySauce/dsh-liang-skin` | A slide-rheostat style skin for the web UI |
| `dsh-approval-gate` (GitHub repo) | Auto-approval gate: pre-judges risky actions, auto-approves safe ones, routes dangerous ones to human (fail-safe) |

## 🔒 Security

This script exists so you run **the official program, not an untrusted repack**:

- ✅ Sole source: `@deepseek-ai/dsh` from the official npm registry
- ✅ Never downloads or runs any third-party executable
- ✅ The entire logic is one `.bat` file you can audit line by line
- ✅ No data collection — the only network activity is installing/updating the official package

## ⚠️ Disclaimer

This is a **community tool**, not an official DeepSeek product. It only downloads and runs the official `@deepseek-ai/dsh` npm package; it is not affiliated with or endorsed by DeepSeek.

## 🧠 How it works

```
double-click
 ├─ already running?      → just open the browser (no duplicate)
 ├─ locally installed?    → start directly (fastest, ~1 s)
 ├─ globally installed?   → use the global dsh
 └─ none of the above?
     ├─ no Node.js        → winget installs Node.js LTS
     └─ first-time install of dsh into %LOCALAPPDATA%\DeepSeek-Harness → start
```

## ❓ FAQ

<details>
<summary><b>Why is the first launch slow?</b></summary>
It downloads the official dsh package (~tens of MB). Later launches take ~1 second and need no internet.
</details>

<details>
<summary><b>Port 3080 is already in use — what now?</b></summary>
Close whatever occupies port 3080, or run <code>start-dsh.bat check</code> to inspect.
</details>

<details>
<summary><b>What exactly does uninstall remove?</b></summary>
Only the local install folder (<code>%LOCALAPPDATA%\DeepSeek-Harness</code>). Your chats, sessions and settings in <code>%USERPROFILE%\.dsh</code> are never touched, and the menu asks for confirmation first.
</details>

<details>
<summary><b>Where are my data / config stored?</b></summary>
Managed by the official dsh program itself; the script doesn't read or upload them.
</details>

<details>
<summary><b>An update failed and the app no longer starts - what now?</b></summary>
Just launch it again: the script detects the broken install and rebuilds automatically. Logs are kept in <code>%LOCALAPPDATA%\DeepSeek-Harness\logs</code>. Run <code>start-dsh.bat check</code> to inspect Node.js/npm versions and the npm proxy setting.
</details>

<details>
<summary><b>Which Node.js version do I need?</b></summary>
Node.js <b>22.19.0 or newer</b> - some dsh dependencies require it. The script checks this on every launch and warns you if your version is too old.
</details>

<details>
<summary><b>Installs are slow or stuck in China - what can I do?</b></summary>
The script switches npm to the China mirror (<code>registry.npmmirror.com</code>) automatically and falls back to the official registry if that fails. To force the official registry, run with <code>DSH_OFFICIAL_REGISTRY=1</code>.
</details>

<details>
<summary><b>Should I remove npm's proxy setting?</b></summary>
If your <code>.npmrc</code> routes npm through a local proxy (for example <code>proxy=http://127.0.0.1:7890</code>), every update fails whenever that proxy is not running. Since the script already uses the China mirror, a direct connection is faster and more reliable - consider removing it:<br>
<code>npm config delete proxy</code><br>
<code>npm config delete https-proxy</code><br>
If you do need the proxy, just keep it running - <code>start-dsh.bat check</code> shows the current proxy setting and reminds you.
</details>

## 📄 License

[MIT](LICENSE) © 2026 Jett-Wu

---

<h1 align="center" id="chinese">🚀 DeepSeek Harness 一键启动器</h1>

<p align="center">
  <b>即下即用 · 只装官方包 · 零配置 · 无第三方代码</b>
</p>

> 双击 `start-dsh.bat`，自动装好一切并打开 <a href="https://www.npmjs.com/package/@deepseek-ai/dsh">DeepSeek Harness</a> 网页版。
> 不依赖任何第三方二次开发的桌面端 —— 直接使用官方 npm 包，安全、稳定、随官方更新。

## ✨ 特性

- 🪄 **零门槛**：没有 Node.js？自动用 winget 安装；首次运行自动装官方包，之后双击秒开
- ⚡ **快**：首次安装后启动约 1 秒；重复双击不会启动第二个实例，直接打开浏览器
- 🔄 **更新提醒**：每次打开菜单都会把本地版本与官方最新版本并列显示，只提醒、绝不擅自安装
- 💾 **可选备份**：如果脚本旁边有 `dsh-backup` 工具（或设置了 `DSH_BACKUP_PS1`），菜单选项 3 可备份聊天记录与插件
- 🛡️ **纯净安全**：只从官方 npm registry 安装 `@deepseek-ai/dsh`，无任何第三方二进制、无数据收集
- 🌍 **通用**：脚本为纯 ASCII，任何语言版本的 Windows 10/11 都能直接运行
- 🚄 **国内加速**：默认把 npm 切到 npmmirror 国内镜像，国内安装飞快；失败自动回退官方源
- 🛠️ **自动修复**：更新失败或 Node.js 升级后，下次启动会自动重建本地安装

## 🚀 快速开始

1. 下载 `start-dsh.bat`
2. 双击后按 `1`（无需回车）
3. 首次运行会自动安装（需要联网，约 1~3 分钟），完成后自动打开 `http://127.0.0.1:3080`

就这么简单，之后的每次启动都是一键。

> 提示：把 `start-dsh.bat` 发送到桌面快捷方式或固定到任务栏，日常使用更顺手。

## 📖 使用方法

双击 `start-dsh.bat` 会出现菜单，按数字键即可（无需回车）。

> 第一次使用 Backup 时会询问备份文件夹，并记住你的选择。

| 菜单 | 操作 | 命令行 |
|---|---|---|
| 1 | 启动 DSH（默认） | `start-dsh.bat start` |
| 2 | 更新到最新版 | `start-dsh.bat update` |
| 3 | 备份聊天记录与插件 | `start-dsh.bat backup` |
| 4 | 环境诊断（可顺带修复） | `start-dsh.bat diagnose` |
| 5 | 卸载 | `start-dsh.bat uninstall` |

## 🧩 推荐插件

以下插件来自社区推荐（非官方维护，建议逐个安装试用，并留意各自仓库的 issues 了解已知问题）：

| 插件 | 简介 |
|---|---|
| `@linxin666/dsh-web-all` | Web UI 全家桶：任务板、Git 图、右侧面板（文件/终端/浏览器）、皮肤中心等一次装齐 |
| `@liustack/modsearch` | 给没有联网能力的模型补上网页搜索 / X 搜索 / 页面抓取，免注册免 key，多引擎自动切换 |
| `dsh-ego-browser` | 给 AI 内置一个浏览器：语义定位点击、填表单、截图 |
| `@kingOfSoySauce/dsh-liang-skin` | 滑动变阻器风格的界面皮肤 |
| `dsh-approval-gate`（GitHub 仓库） | 自动审批门控：预判风险操作，安全的自动批准、危险的转人工确认（fail-safe） |

## 🔒 安全说明

这个脚本的意义，就是让你**用官方程序，而不是来历不明的二次封装**：

- ✅ 唯一安装来源：npm 官方 registry 的 `@deepseek-ai/dsh` 包
- ✅ 不下载、不执行任何第三方可执行文件
- ✅ 全部逻辑就是一个 `.bat` 文件，可逐行审计
- ✅ 不收集任何数据，唯一联网行为是安装/更新官方包本身

## ⚠️ 免责声明

这是一个**社区工具**，不是 DeepSeek 官方产品。它只负责下载并运行官方 `@deepseek-ai/dsh` npm 包，与 DeepSeek 官方无隶属或背书关系。

## 🧠 工作原理

```
双击
 ├─ 服务已在运行？        → 直接开浏览器（不重复启动）
 ├─ 本地已装 dsh？        → 直接启动（最快，约 1 秒）
 ├─ 全局装了 dsh？        → 直接用全局版本
 └─ 都没有？
     ├─ 没 Node.js        → winget 自动安装 Node.js LTS
     └─ 首次安装 dsh 到 %LOCALAPPDATA%\DeepSeek-Harness → 启动
```

## ❓ 常见问题

<details>
<summary><b>首次启动为什么比较久？</b></summary>
正在下载官方 dsh 包（约几十 MB）。之后的启动只需约 1 秒，且无需联网。
</details>

<details>
<summary><b>端口 3080 被占用怎么办？</b></summary>
关闭占用 3080 端口的程序，或先运行 <code>start-dsh.bat check</code> 查看状态。
</details>

<details>
<summary><b>卸载到底会删掉什么？</b></summary>
只删除本地安装目录 <code>%LOCALAPPDATA%\DeepSeek-Harness</code>。你的聊天记录、会话与设置都在 <code>%USERPROFILE%\.dsh</code>，完全不会被碰；删除前还会先让你确认。
</details>

<details>
<summary><b>数据和配置存在哪里？</b></summary>
由官方 dsh 程序自行管理，脚本不参与、不读取、不上传。
</details>

<details>
<summary><b>更新失败后用不了了怎么办？</b></summary>
再启动一次即可：脚本会检测到安装损坏并自动重建。日志保存在 <code>%LOCALAPPDATA%\DeepSeek-Harness\logs</code>；运行 <code>start-dsh.bat check</code> 可以查看 Node.js / npm 版本和 npm 代理设置。
</details>

<details>
<summary><b>需要什么版本的 Node.js？</b></summary>
需要 Node.js <b>22.19.0 或更新</b>（dsh 的部分依赖有此要求）。脚本每次启动都会检查，版本过低时会给出提示。
</details>

<details>
<summary><b>国内安装很慢或卡住怎么办？</b></summary>
脚本会自动把 npm 切到国内镜像 <code>registry.npmmirror.com</code>，失败时自动回退官方源。想强制使用官方源，可设置环境变量 <code>DSH_OFFICIAL_REGISTRY=1</code> 后运行。
</details>

<details>
<summary><b>npm 的代理配置要不要去掉？</b></summary>
如果你的 <code>.npmrc</code> 让 npm 走了本地代理（例如 <code>proxy=http://127.0.0.1:7890</code>），一旦代理没启动，每次更新都会失败。既然脚本已默认使用国内镜像，直连更快也更稳，建议去掉：<br>
<code>npm config delete proxy</code><br>
<code>npm config delete https-proxy</code><br>
如果确实需要代理，保持它常开即可 —— <code>start-dsh.bat check</code> 会显示当前代理配置并给出提醒。
</details>

## 📄 License

[MIT](LICENSE) © 2026 Jett-Wu
