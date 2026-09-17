# Claude Code Instructions for KIRI Engine 3D Reconstruction

This file provides system instructions for Claude Code when executing KIRI Engine 3D reconstruction tasks.

---

## 🎯 Trigger Recognition

Whenever the user's message matches any of the following:
- Contains **"Kiri it"** or **"3D this file"** accompanied by a file or folder path.
- Asks to reconstruct or 3D scan a folder of photos or video using KIRI Engine.

Examples:
- `Kiri it /Users/kiri/Pictures/Shoes_Photos`
- `Kiri it C:\Users\kiri\Pictures\Shoes_Photos`
- `3D this file /Users/kiri/Videos/Sculpture.mp4`

---

## 📋 Execution Protocol

### Step 1: Verify KIRI WebApp Login Status
1. Check if user is logged into KIRI Engine at `https://www.kiriengine.app/webapp` or `https://www.kiriengine.app/webapp/mymodel`.
2. If using browser automation tools (e.g. Chrome DevTools, Playwright, or system browser):
   - Open/navigate to `https://www.kiriengine.app/webapp`.
   - If user is NOT logged in: Prompt the user to log in or register in the browser window:
     > "⚠️ You are not currently logged into KIRI Engine. Please log in or register at https://www.kiriengine.app/webapp in your browser, then reply 'logged in' to continue."
   - Pause execution and wait for user confirmation.
3. If already logged in, proceed immediately to Step 2.

### Step 2: Validate Media Limits (Zero-Dependency)
Run the lightweight cross-platform validation script:
- On Windows (with Python):
  ```cmd
  python scripts\validate_media.py "<PATH>"
  ```
- On Windows (WITHOUT Python installed - zero install):
  ```cmd
  powershell -ExecutionPolicy Bypass -File scripts\validate_media.ps1 "<PATH>"
  ```
- On macOS / Linux:
  ```bash
  python3 scripts/validate_media.py "<PATH>"
  ```
- If Python is missing and user wants it installed:
  - Windows: run `scripts\setup_env.bat`
  - macOS / Linux: run `bash scripts/setup_env.sh`

#### Constraints:
- **Photo Set**: 20 – 300 photos (JPG, PNG, HEIC, WEBP, DNG, etc.), total size ≤ 5 GB.
- **Video**: Exactly 1 video file (MP4, MOV, etc.), duration 3s – 3min (180s), size ≤ 5 GB.

#### Outcome:
- If `valid: false`: Stop and report the exact limitation violation returned in JSON (e.g., photo count < 20 or > 300, video duration outside 3s–180s, or total size > 5 GB). Request valid files.
- If `valid: true`: Output validation summary and proceed to Step 3.

### Step 3: Ask for Reconstruction Mode
Ask the user to select one of the three KIRI Engine reconstruction modes:
1. **Photo Scan** (Standard photogrammetry for objects/scenes with rich texture)
2. **Featureless Object Scan** (Specialized algorithm for featureless, smooth, or reflective objects)
3. **3DGS Scan with Mesh** (3D Gaussian Splatting + Mesh generation)

### Step 4: WebApp Navigation & Upload
1. Navigate to `https://www.kiriengine.app/webapp/mymodel`.
2. Open the entry corresponding to the selected mode.
3. Upload the validated photo files or video file via the upload interface.

### Step 5: Configure Reconstruction Parameters
Prompt the user for the following configuration settings:
- **Model Name**: (Default to folder/file name, user can customize)
- **Export Mesh Format**: Choose from `OBJ`, `FBX`, `STL`, `GLB`, `GLTF`, `USDZ`, `PLY`, `XYZ`
- **Remove Background**: `Yes` / `No`
- **Train AI**: `Agree` / `Disagree`
- **Visibility**: `Public` / `Private`

### Step 6: Submit & Completion Reminder
1. Submit the scan task.
2. Confirm submission and remind the user:
   > "🎉 3D Reconstruction task successfully submitted! Cloud generation typically takes about 10 minutes. Please check your model at https://www.kiriengine.app/webapp/mymodel in 10 minutes."
