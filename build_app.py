import PyInstaller.__main__
import os
import shutil

# Clean previous build with error handling for locked files
try:
    if os.path.exists('dist'):
        shutil.rmtree('dist')
    if os.path.exists('build'):
        shutil.rmtree('build')
except Exception as e:
    print(f"Warning: Could not fully clean build/dist (file might be in use): {e}")

print("Starting build process...")

PyInstaller.__main__.run([
    'main.py',
    '--name=ChessTournamentManager',
    '--onefile',
    '--noconsole',
    # Add UI folder to the root of the executable's temp bundle
    '--add-data=ui;ui',
    # Ensure bridge and database are found (usually picked up, but explicit hidden imports help if dynamic)
    '--hidden-import=backend',
    '--hidden-import=backend.pairing',
    '--hidden-import=backend.models',
    '--icon=ui/assets/icon.png',
    '--clean',
])

print("Build complete. Check dist/ChessTournamentManager.exe")
