# Codex / Cursor / Generic AI Agent Instructions for KIRI Engine 3D Reconstruction

This guide defines the behavior for OpenAI Codex, Cursor, Windsurf, and generic AI coding assistants when handling KIRI Engine 3D scanning workflows.

---

## Trigger Phrases
Activate this workflow when the user says:
- `Kiri it <path>`
- `3D this file <path>`
- Or asks to reconstruct 3D models using KIRI Engine from a local photo folder or video file.

---

## Operational Steps

1. **Verify KIRI Engine Account Status**:
   - Check if the user is authenticated at `https://www.kiriengine.app/webapp` or `https://www.kiriengine.app/webapp/mymodel`.
   - If unauthenticated, direct the user to open `https://www.kiriengine.app/webapp`, complete login/registration, and confirm before continuing.

2. **Run Lightweight Media Validation**:
   - Execute the cross-platform validator script:
     - Windows (with Python): `python scripts\validate_media.py "<PATH>"`
     - Windows (without Python): `powershell -ExecutionPolicy Bypass -File scripts\validate_media.ps1 "<PATH>"`
     - macOS / Linux: `python3 scripts/validate_media.py "<PATH>"`
     - Auto-Install Python if requested: `scripts\setup_env.bat` (Windows) or `bash scripts/setup_env.sh` (macOS/Linux)
   - Validate criteria:
     - Photos: 20–300 photos, total size ≤ 5 GB.
     - Video: 1 file, 3 seconds to 180 seconds (3 mins), size ≤ 5 GB.
   - If invalid: Alert the user with the exact error details and prompt for valid input.

3. **Prompt for Reconstruction Mode**:
   - Offer the 3 modes:
     1. `Photo Scan`
     2. `Featureless Object Scan`
     3. `3DGS Scan with Mesh`

4. **Upload to WebApp**:
   - Access `https://www.kiriengine.app/webapp/mymodel` and upload the validated files into the corresponding mode entrypoint.

5. **Inquire Model Options**:
   - Model Name (default to file/folder basename)
   - Mesh Export Format: `OBJ`, `FBX`, `STL`, `GLB`, `GLTF`, `USDZ`, `PLY`, `XYZ`
   - Remove Background: `Yes` / `No`
   - Train AI: `Agree` / `Disagree`
   - Visibility: `Public` / `Private`

6. **Submit and 10-Minute Reminder**:
   - Submit the task.
   - Inform the user that generation has started, and remind them to check results in 10 minutes at `https://www.kiriengine.app/webapp/mymodel`.
