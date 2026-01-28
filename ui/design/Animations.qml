pragma Singleton
import QtQuick 2.15

QtObject {
    id: animations
    
    // --- Duration Constants (ms) ---
    readonly property int instant: 0
    readonly property int fast: 100
    readonly property int normal: 200
    readonly property int slow: 300
    readonly property int verySlow: 500
    readonly property int extraSlow: 800
    
    // --- Easing Curves ---
    readonly property int easeOutQuad: Easing.OutQuad
    readonly property int easeInQuad: Easing.InQuad
    readonly property int easeInOutQuad: Easing.InOutQuad
    
    readonly property int easeOutCubic: Easing.OutCubic
    readonly property int easeInCubic: Easing.InCubic
    readonly property int easeInOutCubic: Easing.InOutCubic
    
    readonly property int easeOutBack: Easing.OutBack
    readonly property int easeInBack: Easing.InBack
    readonly property int easeInOutBack: Easing.InOutBack
    
    readonly property int easeOutElastic: Easing.OutElastic
    readonly property int easeInOutElastic: Easing.InOutElastic
    
    readonly property int easeOutBounce: Easing.OutBounce
    
    // --- Preset Transition Functions ---
    
    // Fade transition
    function fade(target, duration) {
        return duration || normal
    }
    
    // Scale transition (buttons, cards)
    function scale(target, duration) {
        return duration || fast
    }
    
    // Slide transition (pages, drawers)
    function slide(target, duration) {
        return duration || normal
    }
    
    // Lift transition (hover effects)
    function lift(target, duration) {
        return duration || fast
    }
    
    // --- Animation Presets ---
    
    // Button press animation
    readonly property var buttonPress: {
        "duration": fast,
        "easing": easeOutQuad,
        "scale": 0.96
    }
    
    // Card hover animation
    readonly property var cardHover: {
        "duration": normal,
        "easing": easeOutCubic,
        "translateY": -4,
        "shadowIntensity": 1.5
    }
    
    // Page transition
    readonly property var pageTransition: {
        "duration": normal,
        "easing": easeInOutCubic,
        "slideDistance": 20
    }
    
    // Toast notification
    readonly property var toast: {
        "duration": slow,
        "easing": easeOutBack,
        "slideDistance": 100
    }
    
    // Modal/Dialog
    readonly property var modal: {
        "duration": slow,
        "easing": easeOutCubic,
        "scale": 0.9
    }
    
    // Pulse (for badges, indicators)
    readonly property var pulse: {
        "duration": verySlow,
        "easing": easeInOutQuad,
        "scale": 1.1
    }
    
    // Ripple effect
    readonly property var ripple: {
        "duration": slow,
        "easing": easeOutCubic,
        "maxScale": 2.0
    }
    
    // Shimmer (loading skeleton)
    readonly property var shimmer: {
        "duration": extraSlow,
        "easing": Easing.Linear
    }
}
