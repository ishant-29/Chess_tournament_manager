import sys
import os
from PyQt5.QtCore import QCoreApplication, Qt
from PyQt5.QtGui import QGuiApplication, QIcon
from PyQt5.QtQml import QQmlApplicationEngine, QQmlContext
from PyQt5.QtWidgets import QMessageBox, QApplication

from bridge import BackendBridge

def excepthook(exc_type, exc_value, exc_tb):
    """Catch-all for exceptions - pops up a message box so the user isn't left wondering what broke."""
    import traceback
    error_msg = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
    print(error_msg)
    
    # Create a dummy app if one doesn't exist to show the message box
    if not QApplication.instance():
        _ = QApplication(sys.argv)
    
    msg = QMessageBox()
    msg.setIcon(QMessageBox.Critical)
    msg.setText("An unexpected error occurred.")
    msg.setInformativeText("The application will close. Please contact support with the details below.")
    msg.setDetailedText(error_msg)
    msg.setWindowTitle("System Error")
    msg.exec_()
    sys.exit(1)

def main():
    # Crash handler
    sys.excepthook = excepthook

    # High DPI support
    QCoreApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
    
    app = QGuiApplication(sys.argv)
    app.setOrganizationName("IshantBishnoi")
    app.setOrganizationDomain("ishant.dev")
    app.setApplicationName("Chess Tournament Manager")
    app.setApplicationVersion("1.0.0")
    
    # App Icon
    icon_path = ""
    if getattr(sys, 'frozen', False):
        icon_path = os.path.join(sys._MEIPASS, "ui/assets/icon.png")
    else:
        icon_path = os.path.join(os.path.dirname(__file__), "ui/assets/icon.png")
    
    if os.path.exists(icon_path):
        app.setWindowIcon(QIcon(icon_path))
    
    engine = QQmlApplicationEngine()
    
    # Backend init
    bridge = BackendBridge()
    
    # Connect to QML
    context = engine.rootContext()
    context.setContextProperty("backend", bridge)
    
    # Load UI
    if getattr(sys, 'frozen', False):
        # In frozen state, PyInstaller puts data in sys._MEIPASS
        base_path = sys._MEIPASS
        qml_import_path = os.path.join(base_path, "ui")
        qml_file = os.path.join(qml_import_path, "Main.qml")
        engine.addImportPath(qml_import_path)
    else:
        # standard development path
        qml_file = os.path.join(os.path.dirname(__file__), "ui/Main.qml")
        engine.addImportPath(os.path.join(os.path.dirname(__file__), "ui"))

    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
