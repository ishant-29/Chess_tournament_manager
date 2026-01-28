import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

Popup {
    id: root
    
    // --- Properties ---
    property string title: ""
    property string message: ""
    property string toastType: "info"  // success, error, warning, info
    property int duration: 3000
    property bool autoClose: true
    
    // --- Positioning ---
    y: parent.height - height - ScaleManager.scaleSpacing(Spacing.xl3)
    x: parent.width - width - ScaleManager.scaleSpacing(Spacing.xl3)
    width: ScaleManager.scaleSize(360)
    height: toastContent.implicitHeight + ScaleManager.scaleSpacing(Spacing.base) * 2
    
    modal: false
    focus: false
    closePolicy: Popup.NoAutoClose
    
    // Auto-close timer
    Timer {
        id: closeTimer
        interval: root.duration
        running: root.visible && root.autoClose
        onTriggered: root.close()
    }
    
    // Progress bar for auto-close
    Rectangle {
        id: progressBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: getAccentColor()
        
        NumberAnimation on width {
            id: progressAnimation
            from: root.width
            to: 0
            duration: root.duration
            running: root.visible && root.autoClose
        }
    }
    
    background: Rectangle {
        color: Colors.surfaceElevated
        radius: ScaleManager.scaleRadius(Spacing.radiusMd)
        border.color: getAccentColor()
        border.width: Spacing.borderThin
        
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: ScaleManager.scaleSize(8)
            radius: 24
            samples: 32
            color: Colors.shadowDark
        }
    }
    
    contentItem: RowLayout {
        id: toastContent
        spacing: ScaleManager.scaleSpacing(Spacing.base)
        
        // Icon
        Rectangle {
            width: ScaleManager.scaleSize(40)
            height: ScaleManager.scaleSize(40)
            radius: ScaleManager.scaleSize(20)
            color: Qt.rgba(getAccentColor().r, getAccentColor().g, getAccentColor().b, 0.2)
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: ScaleManager.scaleSpacing(Spacing.base)
            Layout.topMargin: ScaleManager.scaleSpacing(Spacing.base)
            Layout.bottomMargin: ScaleManager.scaleSpacing(Spacing.base)
            
            Text {
                text: getIcon()
                color: getAccentColor()
                font.pixelSize: ScaleManager.scaleFontSize(20)
                font.weight: Typography.bold
                anchors.centerIn: parent
            }
        }
        
        // Content
        ColumnLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.xs)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.topMargin: ScaleManager.scaleSpacing(Spacing.base)
            Layout.bottomMargin: ScaleManager.scaleSpacing(Spacing.base)
            
            Label {
                text: root.title
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                font.weight: Typography.semibold
                color: Colors.textPrimary
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            
            Label {
                text: root.message
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                color: Colors.textSecondary
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
        }
        
        // Close button
        Item {
            width: ScaleManager.scaleSize(24)
            height: ScaleManager.scaleSize(24)
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: ScaleManager.scaleSpacing(Spacing.base)
            Layout.topMargin: ScaleManager.scaleSpacing(Spacing.base)
            Layout.bottomMargin: ScaleManager.scaleSpacing(Spacing.base)
            
            Rectangle {
                anchors.fill: parent
                radius: ScaleManager.scaleSize(12)
                color: closeBtn.containsMouse ? Colors.surfaceHighlight : "transparent"
                
                Text {
                    text: "×"
                    color: Colors.textSecondary
                    font.pixelSize: ScaleManager.scaleFontSize(20)
                    anchors.centerIn: parent
                }
                
                MouseArea {
                    id: closeBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
                
                Behavior on color { ColorAnimation { duration: Animations.fast } }
            }
        }
    }
    
    // --- Animations ---
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "y"
                from: root.parent.height
                to: root.parent.height - root.height - ScaleManager.scaleSpacing(Spacing.xl3)
                duration: Animations.slow
                easing.type: Animations.easeOutBack
            }
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Animations.slow
            }
        }
    }
    
    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: Animations.normal
            }
            NumberAnimation {
                property: "x"
                from: root.x
                to: root.parent.width
                duration: Animations.normal
                easing.type: Animations.easeInQuad
            }
        }
    }
    
    // --- Helper Functions ---
    function getAccentColor() {
        switch(toastType) {
            case "success": return Colors.success
            case "error": return Colors.danger
            case "warning": return Colors.warning
            default: return Colors.info
        }
    }
    
    function getIcon() {
        switch(toastType) {
            case "success": return "✓"
            case "error": return "✕"
            case "warning": return "⚠"
            default: return "ℹ"
        }
    }
    
    // --- Public API ---
    function show(titleText, messageText, type) {
        title = titleText || ""
        message = messageText || ""
        toastType = type || "info"
        open()
    }
}
