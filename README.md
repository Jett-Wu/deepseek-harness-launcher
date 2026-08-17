<h1 align="center">🚀 DeepSeek Harness 一键启动器</h1>

<p align="center">
  <a href="#license"><img alt="License" src="https://img.shields.io/badge/License-MIT-blue.svg"></a>
  <a href="#"><img alt="Platform" src="https://img.shields.io/badge/Windows-10%2F11-0078D6.svg"></a>
  <a href="#"><img alt="Source" src="https://img.shields.io/badge/package-official%20npm-brightgreen.svg"></a>
  <br>
  <b>即下即用 · 只装官方包 · 零配置 · 无第三方代码</b>
</p>

> 双击 `start-dsh.bat`，自动装好一切并打开 <a href="https://www.npmjs.com/package/@deepseek-ai/dsh">DeepSeek Harness</a> 网页版。
> 不依赖任何第三方二次开发的桌面端 —— 直接使用官方 npm 包，安全、稳定、随官方更新。

## ✨ 特性

- 🪄 **零门槛**：没有 Node.js？自动用 winget 安装；首次运行自动装官方包，之后双击秒开
- ⚡ **快**：首次安装后启动约 1 秒；重复双击不会启动第二个实例，直接打开浏览器
- 🔄 **自动更新**：每天后台检查一次更新（完全不拖慢启动），发现新版自动升级
- 🛡️ **纯净安全**：只从官方 npm registry 安装 `@deepseek-ai/dsh`，无任何第三方二进制、无数据收集
- 🌍 **通用**：脚本为纯 ASCII，任何语言版本的 Windows 10/11 都能直接运行

## 🚀 快速开始

1. 下载 `start-dsh.bat`
2. 双击运行
3. 首次运行会自动安装（需要联网，约 1~3 分钟），完成后自动打开 `http://127.0.0.1:3080`

就这么简单，之后的每次启动都是一键。

> 提示：把 `start-dsh.bat` 发送到桌面快捷方式或固定到任务栏，日常使用更顺手。

## 📖 使用方法

| 操作 | 方法 |
|---|---|
| 启动 | 双击 `start-dsh.bat` |
| 更新到最新版 | 命令行运行 `start-dsh.bat update` |
| 检查环境 | 命令行运行 `start-dsh.bat check` |

## 🔒 安全说明

这个脚本的意义，就是让你**用官方程序，而不是来历不明的二次封装**：

- ✅ 唯一安装来源：npm 官方 registry 的 `@deepseek-ai/dsh` 包
- ✅ 不下载、不执行任何第三方可执行文件
- ✅ 全部逻辑就是一个 `.bat` 文件，可逐行审计
- ✅ 不收集任何数据，唯一联网行为是安装/更新官方包本身

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
<summary><b>怎么完全卸载？</b></summary>
删除脚本文件，再删除目录 <code>%LOCALAPPDATA%\DeepSeek-Harness</code>（按 <kbd>Win</kbd>+<kbd>R</kbd> 输入该路径回车即可找到）。
</details>

<details>
<summary><b>数据和配置存在哪里？</b></summary>
由官方 dsh 程序自行管理，脚本不参与、不读取、不上传。
</details>

## 📄 License

[MIT](LICENSE) © 2026 Jett-Wu
