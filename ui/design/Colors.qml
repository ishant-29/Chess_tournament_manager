pragma Singleton
import QtQuick 2.15

QtObject {
    id: colors

    // --- Theme Mode ---
    property bool isDark: false

    // --- Primary Palette (Electric Violet) ---
    property color primary: "#7C3AED"        // Violet 600
    property color primaryLight: "#8B5CF6"   // Violet 500
    property color primaryDark: "#6D28D9"    // Violet 700
    property color primaryHover: "#8B5CF6"
    property color primaryPressed: "#5B21B6" // Violet 800

    // --- Secondary Palette (Bright Teal) ---
    property color secondary: "#0D9488"      // Teal 600
    property color secondaryLight: "#14B8A6" // Teal 500
    property color secondaryDark: "#0F766E"  // Teal 700

    // --- Accent Palette (Hot Pink / Fuchsia) ---
    property color accent: "#DB2777"         // Pink 600
    property color accentLight: "#EC4899"    // Pink 500
    property color accentDark: "#BE185D"     // Pink 700

    // --- Background Layers ---
    property color background: "#F3F4F6"          // Cool Gray 100
    property color backgroundElevated: "#FFFFFF"
    property color surface: "#FFFFFF"
    property color surfaceElevated: "#FFFFFF"
    property color surfaceHighlight: "#F5F3FF"    // Very light violet tint
    property color overlay: "#F8FAFC"

    // --- Text Colors ---
    property color textPrimary: "#1E293B"    // Slate 800
    property color textSecondary: "#475569"  // Slate 600
    property color textTertiary: "#94A3B8"   // Slate 400
    property color textDisabled: "#CBD5E1"   // Slate 300
    property color textOnPrimary: "#FFFFFF"
    property color textOnDark: "#F8FAFC"     // Slage 50

    // --- Border Colors ---
    property color border: "#E2E8F0"         // Slate 200
    property color borderLight: "#F1F5F9"    // Slate 100
    property color borderFocus: primary

    // --- Status Colors ---
    property color success: "#059669"        // Emerald 600
    property color successLight: "#34D399"   // Emerald 400
    property color successDark: "#065F46"    // Emerald 800

    property color warning: "#CA8A04"        // Yellow 600
    property color warningLight: "#FBBF24"   // Yellow 400
    property color warningDark: "#854D0E"    // Yellow 800

    property color danger: "#DC2626"         // Red 600
    property color dangerLight: "#F87171"    // Red 400
    property color dangerDark: "#991B1B"     // Red 800

    property color info: "#0284C7"           // Sky 600
    property color infoLight: "#38BDF8"      // Sky 400
    property color infoDark: "#075985"       // Sky 800

    // --- Chess-Specific Colors ---
    property color white: "#FFFFFF"
    property color black: "#0F172A"
    property color draw: warning
    property color bye: textDisabled
    property color withdrawn: "#64748B"

    // --- Gradient Definitions ---
    function primaryGradient() {
        return {
            start: Qt.point(0, 0),
            end: Qt.point(1, 1),
            stops: [
                { position: 0.0, color: "#7C3AED" }, // Violet 600
                { position: 1.0, color: "#C026D3" }  // Fuchsia 600
            ]
        }
    }

    function sidebarGradient() {
        return {
            start: Qt.point(0, 0),
            end: Qt.point(0, 1), // Top to bottom
            stops: [
                { position: 0.0, color: "#1E1B4B" }, // Indigo 950
                { position: 0.5, color: "#2E1065" }, // Violet 950
                { position: 1.0, color: "#4C0519" }  // Rose 950
            ]
        }
    }

    function cardGradient() {
        return {
            start: Qt.point(0, 0),
            end: Qt.point(0, 1),
            stops: [
                { position: 0.0, color: "#FFFFFF" },
                { position: 1.0, color: "#F8FAFC" }
            ]
        }
    }

    // --- Shadows ---
    property color shadow: "#00000014"         // Lighter, smoother shadow
    property color shadowDark: "#00000029"
    property color shadowLight: "#0000000A"

    // --- Glow Colors ---
    property color glowPrimary: Qt.rgba(0.49, 0.23, 0.93, 0.3)  // Violet glow
    property color glowAccent: Qt.rgba(0.86, 0.15, 0.47, 0.3)   // Pink glow
    property color glowSuccess: Qt.rgba(0.02, 0.59, 0.41, 0.3)
    property color glowDanger: Qt.rgba(0.86, 0.15, 0.15, 0.3)
}
