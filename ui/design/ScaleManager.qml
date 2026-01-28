pragma Singleton
import QtQuick 2.15
import QtQuick.Window 2.15

QtObject {
    id: scaleManager
    
    // --- Scale Properties ---
    property real uiScale: 1.0      // Global UI scale (0.8 - 1.4)
    property real fontScale: 1.0     // Font size scale (0.8 - 1.4)
    
    // --- Scale Limits ---
    readonly property real minScale: 0.8
    readonly property real maxScale: 1.4
    readonly property real scaleStep: 0.1
    readonly property real defaultScale: 1.0
    
    // --- Persistence ---
    property var settings: null  // Will be set by app initialization
    
    // --- Computed Properties ---
    property real effectiveUIScale: Math.max(minScale, Math.min(maxScale, uiScale))
    property real effectiveFontScale: Math.max(minScale, Math.min(maxScale, fontScale))
    
    // --- Scale Functions ---
    function scaleSize(baseSize) {
        return Math.round(baseSize * effectiveUIScale)
    }
    
    function scaleFontSize(baseSize) {
        return Math.round(baseSize * effectiveFontScale)
    }
    
    function scaleRadius(baseRadius) {
        return Math.round(baseRadius * effectiveUIScale)
    }
    
    function scaleSpacing(baseSpacing) {
        return Math.round(baseSpacing * effectiveUIScale)
    }
    
    // --- Zoom Controls ---
    function zoomIn() {
        var newScale = uiScale + scaleStep
        if (newScale <= maxScale) {
            uiScale = Math.round(newScale * 10) / 10  // Round to 1 decimal
            saveSettings()
            console.log("Zoom In:", uiScale)
        }
    }
    
    function zoomOut() {
        var newScale = uiScale - scaleStep
        if (newScale >= minScale) {
            uiScale = Math.round(newScale * 10) / 10
            saveSettings()
            console.log("Zoom Out:", uiScale)
        }
    }
    
    function resetZoom() {
        uiScale = defaultScale
        saveSettings()
        console.log("Reset Zoom:", uiScale)
    }
    
    // --- Font Scale Controls ---
    function increaseFontSize() {
        var newScale = fontScale + scaleStep
        if (newScale <= maxScale) {
            fontScale = Math.round(newScale * 10) / 10
            saveSettings()
            console.log("Font Size Increased:", fontScale)
        }
    }
    
    function decreaseFontSize() {
        var newScale = fontScale - scaleStep
        if (newScale >= minScale) {
            fontScale = Math.round(newScale * 10) / 10
            saveSettings()
            console.log("Font Size Decreased:", fontScale)
        }
    }
    
    function resetFontSize() {
        fontScale = defaultScale
        saveSettings()
        console.log("Reset Font Size:", fontScale)
    }
    
    // --- Settings Persistence ---
    function loadSettings() {
        if (settings) {
            uiScale = settings.value("ui/uiScale", defaultScale)
            fontScale = settings.value("ui/fontScale", defaultScale)
            console.log("Loaded scales - UI:", uiScale, "Font:", fontScale)
        }
    }
    
    function saveSettings() {
        if (settings) {
            settings.setValue("ui/uiScale", uiScale)
            settings.setValue("ui/fontScale", fontScale)
            console.log("Saved scales - UI:", uiScale, "Font:", fontScale)
        }
    }
    
    // --- Percentage Display ---
    function getUIScalePercentage() {
        return Math.round(effectiveUIScale * 100)
    }
    
    function getFontScalePercentage() {
        return Math.round(effectiveFontScale * 100)
    }
}
