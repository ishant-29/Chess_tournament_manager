pragma Singleton
import QtQuick 2.15

QtObject {
    // Colors
    property color background: "#1E1E2E"
    property color surface: "#313244"
    property color surfaceHighlight: "#45475A"
    property color overlay: "#181825"
    
    property color primary: "#89B4FA"
    property color primaryHover: "#B4BEFE"
    property color primaryPressed: "#74C7EC"
    
    property color textPrimary: "#CDD6F4"
    property color textSecondary: "#A6ADC8"
    property color textDisabled: "#6C7086"
    
    property color success: "#A6E3A1"
    property color warning: "#F9E2AF"
    property color danger: "#F38BA8"
    property color info: "#89DCEB"
    property color accent: "#F5C2E7"  // Pink accent color
    property color withdrawn: "#585B70"
    
    property color border: "#45475A"
    
    // Metrics
    property int radius: 12
    property int padding: 16
    property int spacing: 10
    
    // Fonts
    property string fontFamily: "Segoe UI"
    property int h1: 28
    property int h2: 24
    property int h3: 20
    property int body: 14
    property int small: 12
    
    // Shadows
    // (Helper for drop shadow colors)
    property color shadow: "#000000"
}
