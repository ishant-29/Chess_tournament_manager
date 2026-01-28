import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

Dialog {
    id: root
    modal: true
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: ScaleManager.scaleSize(480)
    parent: Overlay.overlay
    
    signal autoSelected()
    signal manualSelected()

    background: Rectangle {
        color: Colors.surfaceElevated
        radius: ScaleManager.scaleRadius(Spacing.radiusLg)
        
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
        
        Text {
            text: "Generate Pairings"
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
            font.weight: Typography.bold
            color: Colors.textPrimary
            Layout.fillWidth: true
        }

        Text {
            text: "Choose how you want to pair this round. Auto-pairing uses the tournament engine rules, while manual allows you to choose specific matchups."
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            color: Colors.textSecondary
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.base)
            
            AppButton {
                text: "Auto Pairing"
                iconLeft: "⚡"
                variant: "primary"
                Layout.fillWidth: true
                size: "lg"
                onClicked: {
                    root.close()
                    root.autoSelected()
                }
            }

            AppButton {
                text: "Manual Setup"
                iconLeft: "✍"
                variant: "ghost"
                Layout.fillWidth: true
                size: "lg"
                onClicked: {
                    root.close()
                    root.manualSelected()
                }
            }
        }
        
        // Footnote
        Rectangle {
            Layout.fillWidth: true
            height: infoText.implicitHeight + ScaleManager.scaleSpacing(Spacing.base)
            color: Colors.surfaceHighlight
            radius: ScaleManager.scaleRadius(Spacing.radiusMd)
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: ScaleManager.scaleSpacing(Spacing.sm)
                spacing: ScaleManager.scaleSpacing(Spacing.sm)
                
                Text {
                    text: "ℹ"
                    color: Colors.info
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                }
                
                Text {
                    id: infoText
                    text: "Auto pairing follows official Swiss/Round Robin rules including colors and score-groups."
                    font.family: Typography.primary
                    color: Colors.textSecondary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
        
        AppButton {
            text: "Cancel"
            variant: "ghost"
            Layout.alignment: Qt.AlignRight
            onClicked: root.close()
        }
    }
    
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
        NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Animations.normal; easing.type: Animations.easeOutBack }
    }
}
