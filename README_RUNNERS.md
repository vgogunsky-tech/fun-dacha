Fun Dacha Validator - Runners

1) Quick run with Python (cross-platform)
- Requires Python 3.10+
- Run bootstrap to create venv, install deps, start app, and open browser:

```bash
python3 packaging/bootstrap.py
```

The app will start on http://localhost:5050 (set PORT env var to change).

2) Build standalone executable (PyInstaller)
- Install PyInstaller in a venv:
```bash
python3 -m venv .venv
. .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt pyinstaller
```
- Build:
```bash
pyinstaller packaging/pyinstaller.spec
```
- The executable will be in `dist/fun-dacha-validator/`.

3) Windows packaging notes
- Use PowerShell:
```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt pyinstaller
pyinstaller packaging/pyinstaller.spec
```
- Run `dist/fun-dacha-validator/fun-dacha-validator.exe`

4) macOS packaging notes
- If running on Apple Silicon, use a Python build for arm64.
- Gatekeeper may block binaries; you may need to right-click Open or sign the app.

5) Auto-install fallback
- The bootstrap script retries installation with `--break-system-packages` if venv install fails (Debian/PEP 668 environments).