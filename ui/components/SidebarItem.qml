import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import "../design"

Item {
    id: root
    
    // --- Properties ---
    property string itemLabel: "Item"
    property string itemIcon: ""
    property bool itemActive: false
    
    signal clicked()
    
    implicitWidth: parent ? parent.width : ScaleManager.scaleSize(200)
    implicitHeight: ScaleManager.scaleSize(44)
    
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool pressed: mouseArea.pressed
    
    Rectangle {
        id: bg
        anchors.fill: parent
        color: getBackgroundColor()
        radius: ScaleManager.scaleRadius(Spacing.radiusMd)
        
        // Active indicator bar
        Rectangle {
            visible: root.itemActive
            width: 3
            height: parent.height * 0.6
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.primary
            radius: 2
            
            // Glow effect
            layer.enabled: true
            layer.effect: Glow {
                samples: 15
                spread: 0.3
                color: Colors.glowPrimary
                radius: 8
            }
        }
        
        Behavior on color {
            ColorAnimation { duration: Animations.fast }
        }
    }
    
    Row {
        anchors.fill: parent
        spacing: ScaleManager.scaleSpacing(Spacing.md)
        leftPadding: ScaleManager.scaleSpacing(Spacing.base)
        
        // Icon
        Text {
            text: root.itemIcon
            font.pixelSize: ScaleManager.scaleFontSize(Typography.h4)
            color: getTextColor()
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // Label
        Label {
            text: root.itemLabel
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            font.weight: root.itemActive ? Typography.semibold : Typography.medium
            color: getTextColor()
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }
    
    // --- Color Functions ---
    function getBackgroundColor() {
        if (root.itemActive) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1) // Soft tint
        if (root.hovered) return Colors.surfaceHighlight
        return "transparent"
    }
    
    function getTextColor() {
        if (root.itemActive) return Colors.primary
        if (root.hovered) return Colors.textPrimary
        return Colors.textSecondary
    }
}

