import QtQuick 2.15
import QtQuick.Controls 2.15
import "../design"

Rectangle {
    id: root
    
    // --- Properties ---
    property string text: ""
    property string variant: "primary"  // primary, success, warning, danger, info, neutral
    property string size: "md"          // sm, md, lg
    property bool pulse: false
    property bool showDot: false
    
    // --- Size Configuration ---
    readonly property int badgeHeight: {
        switch(size) {
            case "sm": return ScaleManager.scaleSize(20)
            case "lg": return ScaleManager.scaleSize(28)
            default: return ScaleManager.scaleSize(Spacing.badgeHeight)
        }
    }
    
    readonly property int fontSize: {
        switch(size) {
            case "sm": return ScaleManager.scaleFontSize(Typography.tiny)
            case "lg": return ScaleManager.scaleFontSize(Typography.small)
            default: return ScaleManager.scaleFontSize(Typography.small)
        }
    }
    
    // --- Styling ---
    implicitWidth: contentRow.width + ScaleManager.scaleSpacing(Spacing.md) * 2
    implicitHeight: badgeHeight
    radius: badgeHeight / 2
    color: getBackgroundColor()
    
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: ScaleManager.scaleSpacing(Spacing.xs)
        
        // Dot indicator
        Rectangle {
            visible: showDot
            width: ScaleManager.scaleSize(6)
            height: ScaleManager.scaleSize(6)
            radius: ScaleManager.scaleSize(3)
            color: getTextColor()
            anchors.verticalCenter: parent.verticalCenter
            
            // Pulse animation
            SequentialAnimation on scale {
                running: pulse && showDot
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.3; duration: Animations.verySlow; easing.type: Animations.easeInOutQuad }
                NumberAnimation { from: 1.3; to: 1.0; duration: Animations.verySlow; easing.type: Animations.easeInOutQuad }
            }
        }
        
        // Text
        Label {
            text: root.text
            color: getTextColor()
            font.family: Typography.primary
            font.pixelSize: fontSize
            font.weight: Typography.semibold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    // --- Color Functions ---
    function getBackgroundColor() {
        switch(variant) {
            case "success": return Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.15)
            case "warning": return Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.15)
            case "danger": return Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.15)
            case "info": return Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.15)
            case "neutral": return Colors.surfaceHighlight
            default: return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
        }
    }
    
    function getTextColor() {
        switch(variant) {
            case "success": return Colors.success
            case "warning": return Colors.warning
            case "danger": return Colors.danger
            case "info": return Colors.info
            case "neutral": return Colors.textSecondary
            default: return Colors.primary
        }
    }
    
    // Pulse animation on whole badge
    SequentialAnimation on scale {
        running: pulse && !showDot
        loops: Animation.Infinite
        NumberAnimation { from: 1.0; to: 1.05; duration: Animations.verySlow; easing.type: Animations.easeInOutQuad }
        NumberAnimation { from: 1.05; to: 1.0; duration: Animations.verySlow; easing.type: Animations.easeInOutQuad }
    }
}
