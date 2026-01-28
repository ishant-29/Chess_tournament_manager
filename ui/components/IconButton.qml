import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import "../design"

Item {
    id: root
    
    // --- Properties ---
    property string btnIcon: ""
    property string btnVariant: "default"  // default, primary, danger, success
    property string btnSize: "md"           // sm, md, lg
    property string btnTooltip: ""
    property bool enabled: true
    
    signal clicked()
    
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed

    // --- Size Configuration ---
    readonly property int buttonSize: {
        switch(btnSize) {
            case "sm": return ScaleManager.scaleSize(32)
            case "lg": return ScaleManager.scaleSize(48)
            default: return ScaleManager.scaleSize(Spacing.iconButtonSize)
        }
    }
    
    readonly property int iconSize: {
        switch(btnSize) {
            case "sm": return ScaleManager.scaleFontSize(18)
            case "lg": return ScaleManager.scaleFontSize(24)
            default: return ScaleManager.scaleFontSize(20)
        }
    }
    
    implicitWidth: buttonSize
    implicitHeight: buttonSize
    
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: buttonSize / 2
        color: getBackgroundColor()
        Behavior on color { ColorAnimation { duration: Animations.fast } }
    }
    
    Text {
        text: root.btnIcon
        font.pixelSize: iconSize
        color: getIconColor()
        anchors.centerIn: parent
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    
    // --- Tooltip ---
    ToolTip.visible: btnTooltip !== "" && hovered
    ToolTip.text: btnTooltip
    ToolTip.delay: 500
    
    // --- Color Functions ---
    function getBackgroundColor() {
        if (!root.enabled) return "transparent"
        if (root.pressed) return Colors.surfaceHighlight
        if (root.hovered) return Qt.rgba(Colors.surfaceHighlight.r, Colors.surfaceHighlight.g, Colors.surfaceHighlight.b, 0.5)
        return "transparent"
    }
    
    function getIconColor() {
        if (!root.enabled) return Colors.textDisabled
        switch(btnVariant) {
            case "primary": return Colors.primary
            case "danger": return Colors.danger
            case "success": return Colors.success
            default: return Colors.textSecondary
        }
    }
    
    // --- Animations ---
    scale: root.pressed ? 0.9 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Animations.fast
            easing.type: Animations.easeOutQuad
        }
    }
}

