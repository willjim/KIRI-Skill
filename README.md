# KIRI Engine 3D Reconstruction Skill (Cross-Platform & Multi-Agent)

这是一个面向通用 AI 编程助手设计的 **KIRI Engine 3D 重建自动化 Skill**。

全面适配 **Google Antigravity**、**Anthropic Claude Code**、**OpenAI Codex**、**Cursor** 等各类主流 Agent，并原生支持 **Windows**、**macOS** 与 **Linux**。

当用户在对话中发送 **「Kiri it」** 或 **「3D this file」** 并给出文件或文件夹路径时，Agent 将自动完成登录检测、轻量合规性校验、模式选择、网页上传、参数配置以及耗时提醒。

---

## 🌟 特性亮点

- ⚡️ **全平台通用与零外部依赖**：**无需安装 ffmpeg、OpenCV 或任何 pip 依赖**。在 Windows、macOS 和 Linux 上均通过纯 Python 标准库流式解析 MP4/MOV 视频头部数据，毫秒级完成照片组与视频文件的尺寸与时长校验。
- 🤖 **多 Agent 生态无缝适配**：
  - **Antigravity**：通过 `SKILL.md` 的 YAML frontmatter 自动识别与渐进加载；
  - **Claude Code**：内置 `CLAUDE.md`，Claude 会在收到触发短语时主动运行校验并引导；
  - **OpenAI Codex / Cursor / Windsurf**：内置 `CODEX.md`，兼容标准 Agentic 规则注入。
- 🛡️ **严格的合规性保护**：严格限制照片（20–300 张，≤ 5 GB）与视频（1 个文件，3秒–3分钟，≤ 5 GB），避免由于格式不合规造成的上传失败或额度浪费。
- 🎨 **完整的参数化定制**：支持模型命名、导出格式挑选（`OBJ`、`FBX`、`STL`、`GLB`、`GLTF`、`USDZ`、`PLY`、`XYZ`）、AI 抠除背景、AI 训练授权与公开/私密可见性。

---

## 📁 目录结构

```text
KIRI-Skill/
├── SKILL.md                     # Antigravity Skill 标准规范
├── CLAUDE.md                    # Claude Code 适配规则
├── CODEX.md                     # OpenAI Codex / Cursor / 通用 Agent 规范
├── README.md                    # 本说明文档
├── scripts/
│   ├── validate_media.py        # 全平台通用、零外部依赖的 Python 校验脚本
│   ├── validate_media.ps1       # Windows 原生内置、免装 Python 的 PowerShell 校验脚本
│   ├── setup_env.bat            # Windows 一键环境检测与安装脚本 (自动 winget)
│   └── setup_env.sh             # macOS / Linux 一键环境检测与安装脚本
└── references/
    └── kiri_workflow.md         # KIRI WebApp 路由、DOM 与交互参考
```

---

## 🚀 安装与配置

### 1. 在 Google Antigravity 中使用

- **当前项目使用**：将本仓库保留在项目目录或 `.agents/skills/kiri-engine-3d/` 中。
- **全局安装（所有项目通用）**：
  - **macOS / Linux**：
    ```bash
    mkdir -p ~/.gemini/config/skills/
    cp -r /Users/kiri/Developer/AI/KIRI-Skill ~/.gemini/config/skills/kiri-engine-3d
    ```
  - **Windows (PowerShell)**：
    ```powershell
    New-Item -ItemType Directory -Force -Path "$HOME\.gemini\config\skills"
    Copy-Item -Recurse -Force "C:\Users\kiri\Developer\AI\KIRI-Skill" "$HOME\.gemini\config\skills\kiri-engine-3d"
    ```

### 2. 在 Claude Code 中使用

直接在包含 `CLAUDE.md` 的项目根目录中运行 Claude Code，或将 `CLAUDE.md` 内容追加到您个人目录的 `~/.claude/CLAUDE.md` 中：
```bash
claude
```
当您在 Claude Code 中发送 `Kiri it ...` 时，Claude 将自动读取规则并执行脚本。

### 3. 在 Cursor / OpenAI Codex / Windsurf 中使用

- 将 `CODEX.md` 的内容添加到项目根目录的 `.cursorrules` 或 Agent 系统提示词中，AI 即可获取触发词感知与校验规程。

---

## 💬 使用示例

在与任意支持的 Agent 对话时，直接发送如下指令之一：

### 示例 1：macOS / Linux 用户
```text
Kiri it /Users/kiri/Pictures/Shoes_Photos
```
或
```text
3D this file /Users/kiri/Videos/Sculpture.mp4
```

### 示例 2：Windows 用户
```cmd
Kiri it C:\Users\kiri\Pictures\Shoes_Photos
```
或
```cmd
3D this file C:\Users\kiri\Videos\Sculpture.mp4
```

---

## 🔄 完整交互流程概览

1. **登录验证**：
   - 检查浏览器是否登录 `www.kiriengine.app/webapp`；
   - 未登录时弹出登录窗口并提示用户完成登录后确认。
2. **格式与尺寸校验**：
   - **已安装 Python 环境**：
     - Windows: `python scripts\validate_media.py "<PATH>"`
     - macOS/Linux: `python3 scripts/validate_media.py "<PATH>"`
   - **未安装 Python 环境（Windows 原生零依赖）**：
     - Windows 自带 PowerShell，无需安装 Python 即可直接运行：
       ```cmd
       powershell -ExecutionPolicy Bypass -File scripts\validate_media.ps1 "<PATH>"
       ```
   - **一键安装 Python 环境（可选）**：
     - Windows：双击或运行 `scripts\setup_env.bat`（自动调用 winget 安装 Python）
     - macOS / Linux：运行 `bash scripts/setup_env.sh`
   - 若照片少于 20 张或视频超出限制，精准警示并暂停。
3. **重建模式选择**：
   - 提示用户选择 `Photo Scan`、`Featureless Object Scan` 或 `3DGS Scan with Mesh`。
4. **上传与参数配置**：
   - 打开 `https://www.kiriengine.app/webapp/mymodel` 对应入口并上传文件；
   - 询问模型名称、Mesh 导出格式（OBJ、FBX、STL、GLB、GLTF、USDZ、PLY、XYZ）、是否去除背景、是否参与 AI 训练、公开或私密。
5. **提交与提醒**：
   - 提交任务，提醒 10 分钟后在 `https://www.kiriengine.app/webapp/mymodel` 查看与下载。
