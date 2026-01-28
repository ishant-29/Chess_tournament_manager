import QtQuick 2.15
import QtQuick.Controls 2.15
import "../design"

TextField {
    id: control
    
    // Properties
    property string label: ""
    property bool hasError: false
    property string errorMessage: ""
    property bool hasSuccess: false
    property string iconPrefix: ""
    property string iconSuffix: ""
    property bool showClearButton: false
    
    // Styling
    font.family: Typography.primary
    font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
    color: Colors.textPrimary
    placeholderTextColor: Colors.textTertiary
    selectionColor: Colors.primary
    selectedTextColor: Colors.textOnPrimary
    
    implicitHeight: ScaleManager.scaleSize(Spacing.inputHeight)
    leftPadding: iconPrefix !== "" ? ScaleManager.scaleSpacing(Spacing.xl4) : ScaleManager.scaleSpacing(Spacing.base)
    rightPadding: (iconSuffix !== "" || showClearButton) ? ScaleManager.scaleSpacing(Spacing.xl2) : ScaleManager.scaleSpacing(Spacing.base)
    
    background: Rectangle {
        color: control.activeFocus ? Colors.backgroundElevated : Colors.background
        radius: ScaleManager.scaleRadius(Spacing.radiusMd)
        border.width: Spacing.borderNormal
        border.color: {
            if (hasError) return Colors.danger
            if (hasSuccess) return Colors.success
            if (control.activeFocus) return Colors.borderFocus
            return Colors.border
        }
        
        // Glow effect on focus
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius + 2
            color: "transparent"
            border.color: {
                if (hasError) return Colors.danger
                if (hasSuccess) return Colors.success
                return Colors.primary
            }
            border.width: 2
            opacity: control.activeFocus ? 0.3 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: Animations.normal }
            }
        }
        
        Behavior on border.color { ColorAnimation { duration: Animations.fast } }
        Behavior on color { ColorAnimation { duration: Animations.fast } }
    }
    
    // Prefix icon
    Text {
        visible: iconPrefix !== ""
        text: iconPrefix
        color: Colors.textSecondary
        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
        anchors.left: parent.left
        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.base)
        anchors.verticalCenter: parent.verticalCenter
    }
    
    // Suffix icon or clear button
    Item {
        visible: iconSuffix !== "" || (showClearButton && control.text !== "")
        width: ScaleManager.scaleSize(20)
        height: ScaleManager.scaleSize(20)
        anchors.right: parent.right
        anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.base)
        anchors.verticalCenter: parent.verticalCenter
        
        // Clear button
        Rectangle {
            visible: showClearButton && control.text !== ""
            anchors.fill: parent
            radius: ScaleManager.scaleSize(10)
            color: clearHover.containsMouse ? Colors.surfaceHighlight : "transparent"
            
            Text {
                text: "×"
                color: Colors.textSecondary
                font.pixelSize: ScaleManager.scaleFontSize(16)
                anchors.centerIn: parent
            }
            
            MouseArea {
                id: clearHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: control.text = ""
            }
            
            Behavior on color { ColorAnimation { duration: Animations.fast } }
        }
        
        // Suffix icon
        Text {
            visible: iconSuffix !== "" && !(showClearButton && control.text !== "")
            text: iconSuffix
            color: Colors.textSecondary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            anchors.centerIn: parent
        }
        
        // Success checkmark
        Text {
            visible: hasSuccess && !showClearButton
            text: "✓"
            color: Colors.success
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            font.weight: Typography.bold
            anchors.centerIn: parent
        }
    }
    
    // Floating label (optional, when label is set)
    Text {
        visible: label !== ""
        text: label
        color: hasError ? Colors.danger : Colors.textSecondary
        font.family: Typography.primary
        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
        font.weight: Typography.medium
        anchors.bottom: parent.top
        anchors.bottomMargin: ScaleManager.scaleSpacing(Spacing.xs)
        anchors.left: parent.left
        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.xs)
    }
    
    // Error message
    Text {
        visible: hasError && errorMessage !== ""
        text: errorMessage
        color: Colors.danger
        font.family: Typography.primary
        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
        anchors.top: parent.bottom
        anchors.topMargin: ScaleManager.scaleSpacing(Spacing.xs)
        anchors.left: parent.left
        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.xs)
    }
}
