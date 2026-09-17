# KIRI Engine 3D WebApp 交互与工作流参考

本指南详细记录 KIRI Engine WebApp 页面逻辑、账号状态检测机制、上传入口与参数配置对应关系，供 Agent 在执行浏览器交互与自动化时参考。

---

## 1. 网址与路由结构

| 页面 | URL | 说明 |
| :--- | :--- | :--- |
| **登录/注册页** | `https://www.kiriengine.app/webapp` | 未登录状态下默认展示登录表单、Google/Apple 第三方登录 |
| **工作台/我的模型** | `https://www.kiriengine.app/webapp/mymodel` | 登录后的主控制台，包含已有模型列表、新建上传入口 |

---

## 2. 账号登录检测机制

### 浏览器端状态判断
在通过 Chrome DevTools 或内置浏览器访问时，可以通过以下指标判断登录状态：
1. **URL 状态**：
   - 若直接访问 `https://www.kiriengine.app/webapp/mymodel` 并保持在 `/mymodel`，或跳转到带有用户标识的工作台，则表明**已登录**。
   - 若被重定向到 `/webapp` 登录表单页，表明**未登录**。
2. **DOM 元素**：
   - 未登录页特征：包含输入框 `input[type="email"]`、`#googleBtn`、`#apple-sign-in` 或 "Log in" / "Sign in" 按钮。
   - 已登录页特征：包含 "Upload" / "New Scan" 按钮、用户头像、积分/额度显示及模型列表。
3. **未登录处理策略**：
   - 导航至 `https://www.kiriengine.app/webapp`。
   - 明确提示用户：“检测到尚未登录 KIRI Engine 账号。已为您打开登录页面，请在内置浏览器窗口中完成登录/注册后回复我继续。”
   - 等待用户确认登录成功后再执行后续上传流程。

---

## 3. 扫描模式与入口对应

| 扫描模式 (Scan Mode) | 适用场景 | WebApp 入口名称 |
| :--- | :--- | :--- |
| **Photo Scan** | 标准多角度照片摄影测量，适合有丰富纹理的物体、环境 | **Photo Scan** |
| **Featureless Object Scan** | 针对无纹理/反光/纯色物体的专用算法重建 | **Featureless Object Scan** |
| **3DGS Scan with Mesh** | 3D Gaussian Splatting 高斯泼溅 + 生成 Mesh 模型 | **3DGS Scan with Mesh** / **Gaussian Splatting** |

---

## 4. 上传与参数设置对应规范

在 `/webapp/mymodel` 点击对应扫描模式后，进入上传与参数设置向导：

1. **文件上传 (Upload Files)**：
   - **照片模式**：上传目录下的所有有效照片文件（20–300 张）。
   - **视频模式**：上传单个短视频文件（3 秒–180 秒）。
2. **模型名称 (Model Name)**：
   - 默认采用所在文件夹名或文件名，用户可自定义。
3. **导出 Mesh 格式 (Mesh Export Format)**：
   - 选项：`OBJ`、`FBX`、`STL`、`GLB`、`GLTF`、`USDZ`、`PLY`、`XYZ`
4. **去除背景 (Remove Background)**：
   - 布尔开关（`Yes` / `No`），开启后算法将利用 AI 自动抠除主体背后的环境与台面。
5. **训练 AI (Train AI)**：
   - 复选框/开关（`Agree` / `Disagree`），是否同意将扫描数据参与匿名模型训练。
6. **可见性 (Visibility)**：
   - 选项：`Public`（公开展示在探索流中）或 `Private`（仅自己可见）。

---

## 5. 完成与后续跟踪

提交上传任务后，WebApp 将把任务放入云端渲染管线：
- 云端处理时间通常在 **5 ~ 15 分钟** 左右（视照片数量及排队状况）。
- 提醒用户关注状态变化，并在 **10 分钟后** 刷新 `https://www.kiriengine.app/webapp/mymodel` 查看最终 3D 模型效果。
