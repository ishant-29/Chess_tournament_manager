import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

Dialog {
    id: editPlayerDialog
    
    // Public properties - set before opening
    property int playerId: -1
    property string playerName: ""
    property string playerClub: ""
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    width: ScaleManager.scaleSize(450)
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape
    
    onOpened: {
        nameField.text = playerName
        clubField.text = playerClub
        nameField.forceActiveFocus()
    }
    
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
        
        // Header
        RowLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            Text {
                text: "✏️"
                font.pixelSize: ScaleManager.scaleFontSize(28)
            }
            
            Text {
                text: "Edit Player"
                color: Colors.textPrimary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                font.weight: Typography.bold
            }
        }
        
        // Name Field
        AppTextField {
            id: nameField
            label: "Player Name"
            placeholderText: "Enter player name"
            Layout.fillWidth: true
            iconPrefix: "👤"
            onAccepted: saveButton.clicked()
        }
        
        // Club Field
        AppTextField {
            id: clubField
            label: "Club / City"
            placeholderText: "e.g. Chess Academy"
            Layout.fillWidth: true
            iconPrefix: "🏢"
            onAccepted: saveButton.clicked()
        }
        
        // Info text
        Text {
            text: "Note: Editing player info does not affect results or standings."
            color: Colors.textTertiary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
            font.italic: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // Actions
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            AppButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: editPlayerDialog.close()
            }
            
            AppButton {
                id: saveButton
                text: "Save Changes"
                variant: "primary"
                iconLeft: "✓"
                enabled: nameField.text.trim() !== ""
                onClicked: {
                    if (nameField.text.trim() !== "" && playerId > 0) {
                        backend.updatePlayer(playerId, nameField.text.trim(), clubField.text.trim())
                        editPlayerDialog.close()
                    }
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
}
