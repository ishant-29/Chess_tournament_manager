import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import "../design"

Item {
    id: root
    
    // Properties
    property string text: ""
    property string variant: "primary"  // primary, secondary, ghost, danger, success
    property string size: "md"          // sm, md, lg
    property bool isLoading: false
    property string iconLeft: ""
    property string iconRight: ""
    property bool enabled: true
    
    signal clicked()
    
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed
    
    // Legacy support
    property bool isGhost: false
    property bool isDanger: false
    
    // Computed Variant
    readonly property string effectiveVariant: {
        if (isDanger) return "danger"
        if (isGhost) return "ghost"
        return variant
    }
    
    // Size Config
    readonly property int buttonHeight: {
        switch(size) {
            case "sm": return ScaleManager.scaleSize(Spacing.buttonHeightSm)
            case "lg": return ScaleManager.scaleSize(Spacing.buttonHeightLg)
            default: return ScaleManager.scaleSize(Spacing.buttonHeightMd)
        }
    }
    
    readonly property int fontSize: {
        switch(size) {
            case "sm": return ScaleManager.scaleFontSize(Typography.small)
            case "lg": return ScaleManager.scaleFontSize(Typography.body)
            default: return ScaleManager.scaleFontSize(Typography.body)
        }
    }
    
    readonly property int horizontalPadding: {
        switch(size) {
            case "sm": return ScaleManager.scaleSpacing(Spacing.base)
            case "lg": return ScaleManager.scaleSpacing(Spacing.xl)
            default: return ScaleManager.scaleSpacing(Spacing.lg)
        }
    }
    
    implicitHeight: buttonHeight
    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2
    
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: ScaleManager.scaleRadius(Spacing.radiusMd)
        color: getBackgroundColor()
        border.color: getBorderColor()
        border.width: (effectiveVariant === "ghost") ? Spacing.borderThin : 0
        
        // Hover overlay for ghost buttons
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: getHoverOverlayColor()
            opacity: root.hovered ? 0.1 : 0
            visible: effectiveVariant === "ghost"
            Behavior on opacity { NumberAnimation { duration: Animations.fast } }
        }
        
        // Glow effect on hover
        layer.enabled: root.hovered && effectiveVariant !== "ghost"
        layer.effect: Glow {
            samples: 20
            spread: 0.3
            color: getGlowColor()
            radius: 8
        }
    }
    
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: ScaleManager.scaleSpacing(Spacing.sm)
        
        // Left Icon
        Text {
            visible: iconLeft !== ""
            text: iconLeft
            color: getTextColor()
            font.family: Typography.primary
            font.pixelSize: fontSize
            font.weight: Typography.semibold
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // Loading Spinner
        Item {
            visible: root.isLoading
            width: fontSize
            height: fontSize
            anchors.verticalCenter: parent.verticalCenter
            
            Rectangle {
                width: fontSize
                height: fontSize
                radius: fontSize / 2
                color: "transparent"
                border.color: getTextColor()
                border.width: 2
                
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 3
                    height: fontSize / 3
                    color: getTextColor()
                }
                
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.isLoading
                }
            }
        }
        
        // Button Text
        Text {
            text: root.text
            font.family: Typography.primary
            font.pixelSize: fontSize
            font.weight: Typography.semibold
            color: getTextColor()
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.isLoading
        }
        
        // Right Icon
        Text {
            visible: iconRight !== ""
            text: iconRight
            color: getTextColor()
            font.family: Typography.primary
            font.pixelSize: fontSize
            font.weight: Typography.semibold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    
    // Color Helpers
    function getBackgroundColor() {
        if (!root.enabled) return Colors.surface
        if (effectiveVariant === "ghost") return "transparent"
        
        var baseColor
        switch(effectiveVariant) {
            case "danger": baseColor = Colors.danger; break
            case "success": baseColor = Colors.success; break
            case "secondary": baseColor = Colors.secondary; break
            default: baseColor = Colors.primary
        }
        
        if (root.pressed) return Qt.darker(baseColor, 1.2)
        if (root.hovered) return Qt.lighter(baseColor, 1.1)
        return baseColor
    }
    
    function getTextColor() {
        if (!root.enabled) return Colors.textDisabled
        if (effectiveVariant === "ghost") {
            switch(variant) {
                case "danger": return Colors.danger
                case "success": return Colors.success
                case "secondary": return Colors.secondary
                default: return Colors.primary
            }
        }
        return Colors.textOnPrimary
    }
    
    function getBorderColor() {
        if (effectiveVariant !== "ghost") return "transparent"
        if (!root.enabled) return Colors.border
        
        switch(variant) {
            case "danger": return Colors.danger
            case "success": return Colors.success
            case "secondary": return Colors.secondary
            default: return Colors.primary
        }
    }
    
    function getHoverOverlayColor() {
        switch(variant) {
            case "danger": return Colors.danger
            case "success": return Colors.success
            case "secondary": return Colors.secondary
            default: return Colors.primary
        }
    }
    
    function getGlowColor() {
        switch(effectiveVariant) {
            case "danger": return Colors.glowDanger
            case "success": return Colors.glowSuccess
            case "secondary": return Colors.glowAccent
            default: return Colors.glowPrimary
        }
    }
    
    // Animations
    scale: root.pressed ? 0.96 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Animations.fast
            easing.type: Animations.easeOutQuad
        }
    }
}

