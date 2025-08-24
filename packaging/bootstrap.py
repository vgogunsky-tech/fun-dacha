#!/usr/bin/env python3
import os
import sys
import subprocess
import webbrowser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENV = ROOT / ".venv"
PY = sys.executable
REQ = ROOT / "requirements.txt"
APP = ROOT / "webapp" / "app.py"


def run(cmd, env=None):
    print("$", " ".join(cmd))
    subprocess.check_call(cmd, env=env)


def ensure_python_and_pip():
    # Assume python3 is available when running this script
    pass


def ensure_venv():
    if VENV.exists():
        return
    # Create venv
    run([PY, "-m", "venv", str(VENV)])


def venv_python() -> str:
    if os.name == "nt":
        return str(VENV / "Scripts" / "python.exe")
    else:
        return str(VENV / "bin" / "python")


def install_requirements():
    p = venv_python()
    # Upgrade pip and install requirements, allow system-managed envs
    run([p, "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"]) 
    run([p, "-m", "pip", "install", "-r", str(REQ)])


def start_app():
    p = venv_python()
    env = os.environ.copy()
    env.setdefault("PORT", "5050")
    # Start Flask app
    proc = subprocess.Popen([p, str(APP)], env=env)
    # Open browser
    webbrowser.open(f"http://localhost:{env['PORT']}")
    # Wait for app process to end
    proc.wait()


def main():
    try:
        ensure_venv()
        install_requirements()
        start_app()
    except subprocess.CalledProcessError as e:
        print("Encountered an error:", e)
        print("Retrying with --break-system-packages for managed envs...")
        # Fallback install with system packages if venv failed
        run([PY, "-m", "pip", "install", "--break-system-packages", "-r", str(REQ)])
        start_app()


if __name__ == "__main__":
    main()