import QtQuick 2.15
import QtQuick.Controls 2.15
import "../design"

Item {
    id: root
    
    // --- Properties ---
    property real value: 0.5           // 0.0 to 1.0
    property bool indeterminate: false
    property bool showPercentage: true
    property bool hasGradient: false
    property string variant: "primary" // primary, success, warning, danger
    
    implicitWidth: 200
    implicitHeight: ScaleManager.scaleSize(8)
    
    // Background track
    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Colors.surfaceHighlight
    }
    
    // Progress fill
    Rectangle {
        id: progressFill
        height: parent.height
        width: indeterminate ? parent.width * 0.3 : parent.width * Math.max(0, Math.min(1, root.value))
        radius: height / 2
        color: hasGradient ? "transparent" : getFillColor()
        
        Rectangle {
            visible: root.hasGradient
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Colors.primary }
                GradientStop { position: 1.0; color: Colors.accent }
            }
        }
        
        Behavior on width {
            enabled: !indeterminate
            NumberAnimation {
                duration: Animations.verySlow
                easing.type: Animations.easeOutCubic
            }
        }
        
        // Indeterminate animation
        SequentialAnimation on x {
            running: indeterminate
            loops: Animation.Infinite
            NumberAnimation {
                from: -progressFill.width
                to: root.width
                duration: 1500
                easing.type: Easing.InOutQuad
            }
        }
    }
    
    // Percentage label
    Label {
        visible: showPercentage && !indeterminate
        text: Math.round(root.value * 100) + "%"
        color: Colors.textPrimary
        font.family: Typography.primary
        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
        font.weight: Typography.semibold
        anchors.left: parent.right
        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.sm)
        anchors.verticalCenter: parent.verticalCenter
    }
    
    // --- Helper Functions ---
    function getFillColor() {
        switch(variant) {
            case "success": return Colors.success
            case "warning": return Colors.warning
            case "danger": return Colors.danger
            default: return Colors.primary
        }
    }
}
