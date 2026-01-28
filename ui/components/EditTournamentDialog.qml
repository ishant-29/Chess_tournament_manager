import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

Dialog {
    id: editTournamentDialog
    
    // Readonly - whether rounds are editable
    property bool canEditRounds: backend && backend.currentTournament && backend.currentTournament.current_round === 0
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    width: ScaleManager.scaleSize(600)
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape
    
    onOpened: {
        if (backend && backend.currentTournament) {
            nameField.text = backend.currentTournament.name || ""
            venueField.text = backend.currentTournament.venue || ""
            roundsSpinbox.value = backend.currentTournament.total_rounds || 5
        }
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
        Text {
            text: "Edit Tournament"
            color: Colors.textPrimary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
            font.weight: Typography.bold
        }
        
        // Name Field
        AppTextField {
            id: nameField
            label: "Tournament Name"
            placeholderText: "Enter tournament name"
            Layout.fillWidth: true
        }
        
        // Venue Field
        AppTextField {
            id: venueField
            label: "Venue"
            placeholderText: "e.g. Grand Hall, City Center"
            Layout.fillWidth: true
            iconPrefix: "📍"
        }
        
        // Rounds
        ColumnLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.xs)
            Layout.fillWidth: true
            
            Label {
                text: "Total Rounds"
                color: Colors.textSecondary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                font.weight: Typography.medium
            }
            
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                
                SpinBox {
                    id: roundsSpinbox
                    from: 1
                    to: 20
                    value: 5
                    enabled: canEditRounds
                    editable: true
                    
                    palette.base: Colors.background
                    palette.text: Colors.textPrimary
                }
                
                // Warning if rounds not editable
                Text {
                    visible: !canEditRounds
                    text: "🔒 Cannot change after tournament starts"
                    color: Colors.warning
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                    font.italic: true
                }
            }
        }
        
        // Actions
        RowLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            Layout.alignment: Qt.AlignRight
            
            AppButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: editTournamentDialog.close()
            }
            
            AppButton {
                text: "Save Changes"
                variant: "primary"
                iconLeft: "✓"
                enabled: nameField.text.trim() !== ""
                onClicked: {
                    if (nameField.text.trim() !== "") {
                        backend.updateTournament(
                            nameField.text.trim(),
                            venueField.text.trim(),
                            roundsSpinbox.value
                        )
                        editTournamentDialog.close()
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
