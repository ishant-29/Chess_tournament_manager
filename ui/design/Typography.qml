pragma Singleton
import QtQuick 2.15

QtObject {
    id: typography
    
    // --- Font Family ---
    // Uses Google Inter font if available, falls back to Segoe UI
    property string primary: "Segoe UI"
    property string mono: "Consolas"
    
    // --- Font Weights ---
    readonly property int light: Font.Light        // 300
    readonly property int regular: Font.Normal     // 400
    readonly property int medium: Font.Medium      // 500
    readonly property int semibold: Font.DemiBold  // 600
    readonly property int bold: Font.Bold          // 700
    readonly property int black: Font.Black        // 900
    
    // --- Font Sizes (Base - will be scaled by ScaleManager) ---
    readonly property int display: 43
    readonly property int h1: 39
    readonly property int h2: 31
    readonly property int h3: 27
    readonly property int h4: 25
    readonly property int body: 21
    readonly property int bodyLarge: 23
    readonly property int small: 19
    readonly property int tiny: 17
    
    // --- Line Heights (multipliers) ---
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5
    readonly property real lineHeightRelaxed: 1.75
    
    // --- Letter Spacing ---
    readonly property real letterSpacingTight: -0.5
    readonly property real letterSpacingNormal: 0
    readonly property real letterSpacingWide: 0.5
    readonly property real letterSpacingWider: 1.0
    
    // --- Helper Functions ---
    function scaled(baseSize, scaleFactor) {
        return Math.round(baseSize * scaleFactor)
    }
    
    // --- Preset Styles ---
    function getDisplayStyle(scaleFactor) {
        return {
            size: scaled(display, scaleFactor),
            weight: black,
            letterSpacing: letterSpacingTight,
            lineHeight: lineHeightTight
        }
    }
    
    function getH1Style(scaleFactor) {
        return {
            size: scaled(h1, scaleFactor),
            weight: bold,
            letterSpacing: letterSpacingTight,
            lineHeight: lineHeightTight
        }
    }
    
    function getH2Style(scaleFactor) {
        return {
            size: scaled(h2, scaleFactor),
            weight: bold,
            letterSpacing: letterSpacingNormal,
            lineHeight: lineHeightNormal
        }
    }
    
    function getH3Style(scaleFactor) {
        return {
            size: scaled(h3, scaleFactor),
            weight: semibold,
            letterSpacing: letterSpacingNormal,
            lineHeight: lineHeightNormal
        }
    }
    
    function getH4Style(scaleFactor) {
        return {
            size: scaled(h4, scaleFactor),
            weight: semibold,
            letterSpacing: letterSpacingNormal,
            lineHeight: lineHeightNormal
        }
    }
    
    function getBodyStyle(scaleFactor) {
        return {
            size: scaled(body, scaleFactor),
            weight: regular,
            letterSpacing: letterSpacingNormal,
            lineHeight: lineHeightNormal
        }
    }
    
    function getSmallStyle(scaleFactor) {
        return {
            size: scaled(small, scaleFactor),
            weight: regular,
            letterSpacing: letterSpacingNormal,
            lineHeight: lineHeightNormal
        }
    }
}
