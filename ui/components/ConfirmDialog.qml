import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

Dialog {
    id: confirmDialog
    
    // Public properties
    property string dialogTitle: "Confirm Action"
    property string dialogMessage: "Are you sure you want to proceed?"
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property string variant: "danger"  // danger, warning, info
    property string iconText: "⚠"
    
    // Signals
    signal confirmed()
    signal cancelled()
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    width: ScaleManager.scaleSize(420)
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape
    
    background: Rectangle {
        color: Colors.surfaceElevated
        radius: ScaleManager.scaleRadius(Spacing.radiusLg)
        border.color: variant === "danger" ? Colors.danger : 
                      variant === "warning" ? Colors.warning : Colors.primary
        border.width: Spacing.borderThin
        
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 32
            samples: 48
            color: Colors.shadowDark
            verticalOffset: ScaleManager.scaleSize(8)
        }
    }
    
    contentItem: ColumnLayout {
        spacing: ScaleManager.scaleSpacing(Spacing.xl)
        
        // Icon & Title
        RowLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            Text {
                text: iconText
                font.pixelSize: ScaleManager.scaleFontSize(32)
                color: variant === "danger" ? Colors.danger : 
                       variant === "warning" ? Colors.warning : Colors.primary
            }
            
            Text {
                text: dialogTitle
                color: Colors.textPrimary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                font.weight: Typography.bold
            }
        }
        
        // Message
        Text {
            text: dialogMessage
            color: Colors.textSecondary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Actions
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            AppButton {
                text: cancelText
                variant: "ghost"
                onClicked: {
                    confirmDialog.cancelled()
                    confirmDialog.close()
                }
            }
            
            AppButton {
                text: confirmText
                variant: confirmDialog.variant
                iconLeft: variant === "danger" ? "×" : "✓"
                onClicked: {
                    confirmDialog.confirmed()
                    confirmDialog.close()
                }
            }
        }
    }
    
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "scale"
                from: 0.9
                to: 1.0
                duration: Animations.slow
                easing.type: Animations.easeOutCubic
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
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: Animations.fast
        }
    }
}
