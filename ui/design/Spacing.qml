pragma Singleton
import QtQuick 2.15

QtObject {
    id: spacing
    
    // --- 8-Point Grid System (Base) ---
    readonly property int unit: 8
    
    readonly property int xs: 4      // 0.5 units
    readonly property int sm: 8      // 1 unit
    readonly property int md: 12     // 1.5 units
    readonly property int base: 16   // 2 units
    readonly property int lg: 20     // 2.5 units
    readonly property int xl: 24     // 3 units
    readonly property int xl2: 32    // 4 units
    readonly property int xl3: 40    // 5 units
    readonly property int xl4: 48    // 6 units
    readonly property int xl5: 64    // 8 units
    
    // --- Padding Presets ---
    readonly property int paddingTight: sm
    readonly property int paddingNormal: base
    readonly property int paddingLoose: xl
    readonly property int paddingCard: base
    readonly property int paddingPage: xl3
    
    // --- Margin Presets ---
    readonly property int marginTiny: xs
    readonly property int marginSmall: sm
    readonly property int marginNormal: base
    readonly property int marginLarge: xl
    
    // --- Border Radius ---
    readonly property int radiusNone: 0
    readonly property int radiusSm: 6
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 24
    readonly property int radiusFull: 9999
    
    // --- Border Width ---
    readonly property int borderThin: 1
    readonly property int borderNormal: 2
    readonly property int borderThick: 3
    
    // --- Component Sizes ---
    readonly property int buttonHeightSm: 36
    readonly property int buttonHeightMd: 44
    readonly property int buttonHeightLg: 52
    
    readonly property int inputHeight: 44
    readonly property int iconButtonSize: 40
    readonly property int avatarSize: 44
    readonly property int badgeHeight: 28
    
    // --- Sidebar ---
    readonly property int sidebarWidthCollapsed: 80
    readonly property int sidebarWidthExpanded: 240
    
    // --- Header ---
    readonly property int headerHeight: 64
    
    // --- Helper Functions ---
    function scaled(baseValue, scaleFactor) {
        return Math.round(baseValue * scaleFactor)
    }
    
    function multiple(multiplier) {
        return unit * multiplier
    }
}
