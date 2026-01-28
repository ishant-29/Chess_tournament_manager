import QtQuick 2.15
import QtQuick.Controls 2.15
import "../design"

Rectangle {
    id: root
    
    // --- Properties ---
    property string text: ""
    property string variant: "default"  // default, primary, success, warning, danger, info
    property bool closeable: false
    
    signal closeClicked()
    
    // --- Styling ---
    implicitWidth: contentRow.width + ScaleManager.scaleSpacing(Spacing.base) * 2
    implicitHeight: ScaleManager.scaleSize(28)
    radius: ScaleManager.scaleRadius(Spacing.radiusSm)
    color: getBackgroundColor()
    
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: ScaleManager.scaleSpacing(Spacing.sm)
        
        Label {
            text: root.text
            color: getTextColor()
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
            font.weight: Typography.medium
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // Close button
        Rectangle {
            visible: closeable
            width: ScaleManager.scaleSize(16)
            height: ScaleManager.scaleSize(16)
            radius: ScaleManager.scaleSize(8)
            color: closeHover.containsMouse ? Qt.darker(getBackgroundColor(), 1.2) : "transparent"
            anchors.verticalCenter: parent.verticalCenter
            
            Text {
                text: "×"
                color: getTextColor()
                font.pixelSize: ScaleManager.scaleFontSize(14)
                font.weight: Typography.bold
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeClicked()
            }
            
            Behavior on color { ColorAnimation { duration: Animations.fast } }
        }
    }
    
    // --- Color Functions ---
    function getBackgroundColor() {
        switch(variant) {
            case "primary": return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
            case "success": return Qt.rgba(Colors.success.r, Colors.success.g, Colors.success.b, 0.15)
            case "warning": return Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.15)
            case "danger": return Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.15)
            case "info": return Qt.rgba(Colors.info.r, Colors.info.g, Colors.info.b, 0.15)
            default: return Colors.surfaceHighlight
        }
    }
    
    function getTextColor() {
        switch(variant) {
            case "primary": return Colors.primary
            case "success": return Colors.success
            case "warning": return Colors.warning
            case "danger": return Colors.danger
            case "info": return Colors.info
            default: return Colors.textSecondary
        }
    }
}
