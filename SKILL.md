---
name: kiri-engine-3d
description: Cross-platform 3D reconstruction skill for KIRI Engine. Triggers when the user says "Kiri it" or "3D this file" with a file or folder path. Compatible with Antigravity, Claude Code, and Codex across Windows, macOS, and Linux. Validates media limits (20-300 photos or 3s-3min video, <= 5GB), checks login at www.kiriengine.app/webapp, prompts for scan mode, handles upload at /webapp/mymodel, configures parameters, and provides completion reminders.
---

# KIRI Engine 3D Reconstruction Skill (Cross-Platform & Multi-Agent)

本 Skill 用于跨平台（Windows / macOS / Linux）与多 Agent（Google Antigravity、Anthropic Claude Code、OpenAI Codex、Cursor 等）自动化 KIRI Engine Web 端的 3D 重建全流程。

当用户在对话中发送 **「Kiri it」** 或 **「3D this file」** 并给出照片文件夹或视频路径时，引导 Agent 完成完整的合规性校验、网页端交互与参数配置。

---

## 触发条件 (Trigger Conditions)

当用户的提示词中包含以下意图时激活本 Skill：
- 包含关键词 **「Kiri it」** 或 **「3D this file」**，并附带文件或文件夹路径。
  - 示例 1（macOS/Linux）：`Kiri it /Users/kiri/Pictures/Shoes_Photos`
  - 示例 2（Windows）：`Kiri it C:\Users\kiri\Pictures\Shoes_Photos`
  - 示例 3：`3D this file /Users/kiri/Videos/Sculpture.mp4`
  - 示例 4（Antigravity 专属联动）：`/browser Kiri it /Users/kiri/Videos/Sculpture.mp4`
- 或明确要求使用 KIRI Engine 对某组照片或某个视频进行 3D 建模/三维重建。

---

## 🌐 Antigravity 默认执行机制：联动 `/browser` 专属能力

在 Google Antigravity 中执行本 Skill 时，**默认设置调用 `/browser` 专属能力**：
1. **职责划分**：
   - **本地端**：主 Agent 执行媒体格式与时长轻量校验（`validate_media.py` / `validate_media.ps1`），并通过交互式点击菜单（`ask_question`）确认用户重建模式与导出参数；
   - **网页端**：默认调用 Antigravity 的 `/browser` 专属能力接管内置浏览器，直接进行 DOM 级自动化操作：
     - 自动检测 `https://www.kiriengine.app/webapp` 登录状态（未登录自动弹出登录框）；
     - 自动进入 `https://www.kiriengine.app/webapp/mymodel`；
     - 自动定位模式入口，向 `<input type="file">` 控件注入本地文件完成真实上传；
     - 自动根据用户配置勾选 Mesh 格式、背景抠除、Train AI 与可见性，并点击提交。
2. **会话级自适应**：
   - 若当前会话已有浏览器工具权限，直接自动操控上传；
   - 若当前会话尚未加载浏览器工具，Agent 默认联动并推荐使用 `/browser` 命令（如 `/browser Kiri it <path>`），以激活完整的浏览器自动化工具链。

---

## 执行步骤与规范流程

### 步骤 1：调用 `/browser` 专属能力验证 KIRI 账号登录状态

在执行上传前，默认联动 `/browser` 能力检查内置浏览器登录状态：

1. **访问/检查页面**：
   - 打开或检查浏览器当前页面：`https://www.kiriengine.app/webapp` 或 `https://www.kiriengine.app/webapp/mymodel`。
2. **状态判断**：
   - **若未登录**（页面停留在登录表单、包含输入框或第三方登录按钮，或从 `/mymodel` 被自动重定向至 `/webapp`）：
     - 弹出/跳转至登录界面：`https://www.kiriengine.app/webapp`。
     - **明确提示用户**：
       > “检测到您尚未在浏览器中登录 KIRI Engine 账号。已为您打开登录界面（https://www.kiriengine.app/webapp ），请在浏览器中完成登录或注册后，回复我‘已登录’以继续。”
     - **等待用户完成登录后**方可进入下一步。
   - **若已登录**（页面能够正常访问 `https://www.kiriengine.app/webapp/mymodel` 并显示模型列表或用户工作台）：
     - 直接进入步骤 2。

---

### 步骤 2：跨平台轻量媒体文件合规性校验

Agent 在执行校验前，可快速检查环境：
- **默认方式（跨平台 Python 引擎）**：
  - macOS / Linux：`python3 scripts/validate_media.py "<用户给出的文件或文件夹绝对路径>"`
  - Windows：`python scripts\validate_media.py "<用户给出的文件或文件夹绝对路径>"`
- **免 Python 应急方式（针对未安装 Python 的 Windows 用户）**：
  - Windows 原生内置 PowerShell，**无需安装任何环境**直接执行：
    ```cmd
    powershell -ExecutionPolicy Bypass -File scripts\validate_media.ps1 "<用户给出的文件或文件夹绝对路径>"
    ```
- **一键安装环境（若用户需要安装 Python）**：
  - Windows：运行 `scripts\setup_env.bat`（自动调用 Windows 自带的 winget 安装 Python）
  - macOS/Linux：运行 `bash scripts/setup_env.sh`

#### 校验标准：
- **照片组（文件夹）**：
  - 照片数量：**20 – 300 张**（支持常见格式：JPG, PNG, HEIC, WEBP, DNG 等）；
  - 总文件大小：**≤ 5 GB**。
- **视频文件（单个视频）**：
  - 视频数量：**仅限 1 个文件**（支持 MP4, MOV 等）；
  - 视频时长：**3 秒 至 3 分钟 (180s)**；
  - 文件大小：**≤ 5 GB**。

#### 结果处理：
- **如果校验未通过（Exit code ≠ 0 或 `valid: false`）**：
  - 提取脚本返回的具体错误描述（如：“当前仅包含 12 张照片，少于最低 20 张限制” 或 “视频时长为 2 秒，不足 3 秒限制” 或 “文件体积超出 5 GB”）。
  - 立即终止上传流程，向用户发出警示并提示：
    > ⚠️ **文件未满足 KIRI Engine 限制**：[具体错误详情]  
    > 请重新整理或选择符合规范的文件/文件夹后再次重试。
- **如果校验通过（`valid: true`）**：
  - 简要向用户反馈校验成功摘要（如：“检测通过：共 48 张照片，总大小 180 MB”），然后进入步骤 3。

---

### 步骤 3：交互式菜单选择 3D 重建模式

**必须使用交互式选择菜单（如 Antigravity 的 `ask_question` 工具、Claude Code / CLI 的单选菜单）**，让用户直接点击选项，禁止让用户纯文本手动输入：

- **选项设置**：
  1. `(Recommended) Photo Scan`（适用于常规带有丰富表面纹理的物体与场景）
  2. `Featureless Object Scan`（适用于表面缺乏纹理、光滑反光或纯色的物体）
  3. `3DGS Scan with Mesh`（基于 3D 高斯泼溅技术，兼顾实时高保真辐射场与网格 Mesh）

---

### 步骤 4：通过 `/browser` 专属能力进入 WebApp 并自动上传文件

在 Antigravity 中，默认由 `/browser` 自动化执行以下操作（若当前会话未开启浏览器工具，则自动启动或提示 `/browser`）：
1. 浏览器导航至：`https://www.kiriengine.app/webapp/mymodel`
2. 自动化定位并点击新建扫描入口（按步骤 3 选定的 `Photo Scan` / `Featureless Object Scan` / `3DGS Scan with Mesh`）。
3. 定位页面上的文件上传控件（`<input type="file">`），将步骤 2 中已验证通过的文件或文件夹内全部媒体自动注入并开始上传。
4. 监控上传进度直至 100% 完成。

---

### 步骤 5：交互式菜单确认模型配置参数

**同样必须使用多选/单选交互式菜单（如 `ask_question` 或对应交互控件）**，将参数分拆为可点击选项，用户直接勾选或点击，默认模型名称取自文件名或文件夹名：

1. **导出 Mesh 格式 (Mesh Export Format)**（支持多选）：
   - `GLB`、`OBJ`、`FBX`、`USDZ`、`STL`、`GLTF`、`PLY`、`XYZ`
2. **Remove Background（是否去除背景）**（单选，两选一）：
   - `(Recommended) 否（保留原始环境与背景）`
   - `是（使用 AI 自动抠除背景，仅保留主体）`
3. **Train AI（是否同意数据参与 AI 训练）**（单选，两选一）：
   - `(Recommended) 同意`
   - `不同意`
4. **Visibility（模型公开可见性）**（单选，两选一）：
   - `(Recommended) Private（私密 / 仅自己可见）`
   - `Public（公开分享）`
5. **模型名称 (Model Name)**：默认采用所选文件或文件夹名（支持自定义输入）。

---

### 步骤 6：提交任务并完成引导

1. 点击“Submit”或“Start Processing”提交重建任务。
2. 确认任务提交成功后，向用户发送完成提示：
   > 🎉 **3D 重建任务已成功提交！**  
   > 
   > - **模型名称**：`<模型名称>`
   > - **重建模式**：`<选定模式>`
   > - **导出格式**：`<选定格式>`
   > 
   > 💡 **耗时提醒**：云端高质量三维重建与纹理映射通常需要约 **10 分钟**。请在 10 分钟后打开 [www.kiriengine.app/webapp/mymodel](https://www.kiriengine.app/webapp/mymodel) 查看生成效果与下载模型文件。

---

## 适配体系与辅助文件

- **轻量跨平台校验脚本**：`scripts/validate_media.py`
- **Claude Code 指导规则**：`CLAUDE.md`
- **Codex / Cursor 指导规则**：`CODEX.md`
- **WebApp 流程参考**：`references/kiri_workflow.md`
