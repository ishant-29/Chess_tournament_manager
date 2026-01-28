import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"
import "design"

Page {
    title: "Pairings"
    background: Rectangle { color: "transparent" }
    
    property int selectedPlayerId: -1
    property int selectedWhiteId: -1
    property int selectedBlackId: -1

    function getPlayerName(pid) {
        if (!backend || !backend.playerList) return ""
        for (var i = 0; i < backend.playerList.length; i++) {
            if (backend.playerList[i].id === pid) return backend.playerList[i].name
        }
        return "Unknown"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScaleManager.scaleSpacing(Spacing.paddingPage)
        spacing: ScaleManager.scaleSpacing(Spacing.xl)
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.lg)
            
            // Round Navigation
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.sm)
                
                IconButton {
                    btnIcon: "◀"
                    // btnSize: "sm" (Removed to use default md size)
                    btnVariant: "ghost"
                    enabled: backend && backend.viewingRoundNumber > 1
                    onClicked: backend.setViewRound(backend.viewingRoundNumber - 1)
                    btnTooltip: "Previous Round"
                }

                Text {
                    text: {
                        if (!backend) return "Round -"
                        return "Round " + backend.viewingRoundNumber
                    }
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
                    font.weight: Typography.black
                    color: Colors.textPrimary
                    Layout.preferredWidth: ScaleManager.scaleSize(140)
                    horizontalAlignment: Text.AlignHCenter
                }

                IconButton {
                    btnIcon: "▶"
                    // btnSize: "sm" (Removed to use default md size)
                    btnVariant: "ghost"
                    enabled: backend && backend.currentTournament && backend.viewingRoundNumber > 0 && backend.viewingRoundNumber < backend.currentTournament.current_round
                    onClicked: backend.setViewRound(backend.viewingRoundNumber + 1)
                    btnTooltip: "Next Round"
                }
            }
            
            // Status Badge
            AppBadge {
                text: backend && backend.isRoundLocked ? "LOCKED" : "IN PROGRESS"
                variant: backend && backend.isRoundLocked ? "neutral" : "success"
                showDot: !(backend && backend.isRoundLocked)
                pulse: !(backend && backend.isRoundLocked)
                size: "md"
            }
            
            Item { Layout.fillWidth: true }
             
            // Edit / Lock Controls
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                
                AppButton {
                    text: (backend && backend.isRoundLocked) ? "Unlock & Edit" : "Lock Results"
                    variant: (backend && backend.isRoundLocked) ? "ghost" : "primary"
                    iconLeft: (backend && backend.isRoundLocked) ? "🔓" : "🔒"
                    visible: backend && (backend.isViewingPastRound || backend.isRoundLocked)
                    onClicked: {
                        if (backend && backend.isRoundLocked) {
                            unlockDialog.open()
                        } else {
                            backend.lockRound(backend.viewingRoundNumber)
                            globalToast.show("Round Locked", "Standings have been updated", "success")
                        }
                    }
                }
                
                AppButton {
                    text: "Print Sheet"
                    variant: "ghost"
                    iconLeft: "🖨"
                    enabled: backend && backend.viewingRoundNumber > 0
                    onClicked: backend.printRoundReport(backend.viewingRoundNumber)
                }
            }
        }
        
        // Manual Pairing Editor
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: ScaleManager.scaleSize(300)
            visible: backend && backend.isPairingModeManual && !(backend.isRoundLocked)
            spacing: ScaleManager.scaleSpacing(Spacing.xl)
            
            // Left: Player Pool
            AppCard {
                Layout.fillHeight: true
                Layout.preferredWidth: ScaleManager.scaleSize(300)
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScaleManager.scaleSpacing(Spacing.md)
                    
                    Text {
                        text: "Unpaired Players"
                        font.family: Typography.primary
                        font.weight: Typography.bold
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                        color: Colors.textPrimary
                    }
                    
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        
                        ListView {
                            model: {
                                if (!backend || !backend.playerList) return []
                                var pairedIds = []
                                for(var i=0; i<backend.pairingList.length; i++) {
                                    var p = backend.pairingList[i]
                                    if(p.white_player_id) pairedIds.push(p.white_player_id)
                                    if(p.black_player_id) pairedIds.push(p.black_player_id)
                                }
                                var result = []
                                for(var j=0; j<backend.playerList.length; j++) {
                                    var pl = backend.playerList[j]
                                    if(pairedIds.indexOf(pl.id) === -1 && pl.status === "ACTIVE") {
                                        result.push(pl)
                                    }
                                }
                                return result
                            }
                            
                            delegate: Rectangle {
                                width: parent.width
                                height: ScaleManager.scaleSize(40)
                                color: selectedPlayerId === modelData.id ? Colors.primaryGlow : (pMouse.hovered ? Colors.surfaceHighlight : "transparent")
                                radius: ScaleManager.scaleRadius(Spacing.radiusSm)
                                
                                Text {
                                    text: modelData.name + " (" + modelData.points + ")"
                                    anchors.centerIn: parent
                                    color: selectedPlayerId === modelData.id ? Colors.primary : Colors.textPrimary
                                    font.family: Typography.primary
                                    font.weight: selectedPlayerId === modelData.id ? Typography.bold : Typography.medium
                                }
                                
                                HoverHandler { id: pMouse }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: selectedPlayerId = (selectedPlayerId === modelData.id ? -1 : modelData.id)
                                }
                                
                                Behavior on color { ColorAnimation { duration: Animations.fast } }
                            }
                        }
                    }
                }
            }
            
            // Center: Assignment View
            ColumnLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.lg)
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    text: "Manual Assignment"
                    font.family: Typography.primary
                    font.weight: Typography.bold
                    color: Colors.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }
                
                RowLayout {
                    spacing: ScaleManager.scaleSpacing(Spacing.xl)
                    
                    // White Selection
                    Column {
                        spacing: ScaleManager.scaleSpacing(Spacing.sm)
                        AppButton {
                            text: selectedWhiteId > 0 ? getPlayerName(selectedWhiteId) : "Select White"
                            variant: selectedWhiteId > 0 ? "primary" : "ghost"
                            size: "lg"
                            onClicked: {
                                if (selectedPlayerId > 0) {
                                    if (selectedPlayerId === selectedBlackId) {
                                        globalToast.show("Invalid Selection", "Player cannot play against themselves", "error")
                                        return
                                    }
                                    selectedWhiteId = selectedPlayerId
                                    selectedPlayerId = -1
                                } else if (selectedWhiteId > 0) {
                                    selectedWhiteId = -1
                                }
                            }
                        }
                        Text { text: "♙ White Pieces"; color: Colors.textTertiary; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                    
                    Text { text: "VS"; font.weight: Typography.black; color: Colors.textDisabled }
                    
                    // Black Selection
                    Column {
                        spacing: ScaleManager.scaleSpacing(Spacing.sm)
                        AppButton {
                            text: selectedBlackId > 0 ? getPlayerName(selectedBlackId) : "Select Black"
                            variant: selectedBlackId > 0 ? "secondary" : "ghost"
                            size: "lg"
                            onClicked: {
                                if (selectedPlayerId > 0) {
                                    if (selectedPlayerId === selectedWhiteId) {
                                        globalToast.show("Invalid Selection", "Player cannot play against themselves", "error")
                                        return
                                    }
                                    selectedBlackId = selectedPlayerId
                                    selectedPlayerId = -1
                                } else if (selectedBlackId > 0) {
                                    selectedBlackId = -1
                                }
                            }
                        }
                        Text { text: "♟ Black Pieces"; color: Colors.textTertiary; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
                
                RowLayout {
                    spacing: ScaleManager.scaleSpacing(Spacing.md)
                    Layout.alignment: Qt.AlignHCenter
                    
                    AppButton {
                        text: "Save Pairing"
                        variant: "success"
                        enabled: (selectedWhiteId > 0 || selectedBlackId > 0) && (selectedWhiteId !== selectedBlackId)
                        onClicked: {
                            backend.saveManualPairing("*", selectedWhiteId, selectedBlackId)
                            selectedWhiteId = -1
                            selectedBlackId = -1
                            globalToast.show("Pairing Created", "Board added to list", "success")
                        }
                    }
                    
                    AppButton {
                        text: "Reset"
                        variant: "ghost"
                        onClicked: {
                            selectedWhiteId = -1
                            selectedBlackId = -1
                            selectedPlayerId = -1
                        }
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
        }

        // Pairing List
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            
            ListView {
                id: pairingView
                width: parent.width
                model: backend ? backend.pairingList : []
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                
                header: RowLayout {
                    width: parent.width
                    visible: pairingView.count > 0
                    Layout.margins: ScaleManager.scaleSpacing(Spacing.sm)
                    
                    Text { text: "Bd"; font.pixelSize: 12; color: Colors.textTertiary; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                    Text { text: "White Player"; font.pixelSize: 12; color: Colors.textTertiary; Layout.fillWidth: true }
                    Text { text: "Score"; font.pixelSize: 12; color: Colors.textTertiary; Layout.preferredWidth: 200; horizontalAlignment: Text.AlignHCenter }
                    Text { text: "Black Player"; font.pixelSize: 12; color: Colors.textTertiary; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                }
                
                delegate: AppCard {
                    id: pairingCard
                    width: parent.width
                    height: ScaleManager.scaleSize(72)
                    hoverable: true
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.base)
                        anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.base)
                        spacing: ScaleManager.scaleSpacing(Spacing.lg)
                        
                        // Board Number
                        Rectangle {
                            width: ScaleManager.scaleSize(32)
                            height: ScaleManager.scaleSize(32)
                            radius: 16
                            color: Colors.surfaceHighlight
                            Text {
                                text: index + 1
                                font.weight: Typography.bold
                                color: Colors.textSecondary
                                anchors.centerIn: parent
                            }
                        }
                        
                        // White Player
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScaleManager.scaleSpacing(Spacing.sm)
                            
                            Rectangle {
                                width: 12; height: 12; radius: 3
                                color: "#FFFFFF"; border.color: Colors.border
                            }
                            
                            Text {
                                text: model.modelData.white_player_name
                                font.family: Typography.primary
                                font.weight: model.modelData.result === "1-0" ? Typography.black : Typography.bold
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                                color: model.modelData.result === "1-0" ? Colors.primary : Colors.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        
                        // Result Selector - Normal Games
                        Row {
                            spacing: ScaleManager.scaleSpacing(Spacing.xs)
                            visible: !(backend && backend.isRoundLocked) && model.modelData.black_player_name !== "BYE" && model.modelData.white_player_name !== "BYE"
                            
                            AppButton {
                                text: "1 - 0"
                                size: "sm"
                                variant: model.modelData.result === "1-0" ? "primary" : "ghost"
                                onClicked: backend.setResult(model.modelData.id, "1-0")
                            }
                            
                            AppButton {
                                text: "½ - ½"
                                size: "sm"
                                variant: model.modelData.result === "0.5-0.5" ? "secondary" : "ghost"
                                onClicked: backend.setResult(model.modelData.id, "0.5-0.5")
                            }
                            
                            AppButton {
                                text: "0 - 1"
                                size: "sm"
                                variant: model.modelData.result === "0-1" ? "primary" : "ghost"
                                onClicked: backend.setResult(model.modelData.id, "0-1")
                            }
                        }
                        
                        // Result Selector - BYE Games (Auto 1 point)
                        Row {
                            spacing: ScaleManager.scaleSpacing(Spacing.xs)
                            visible: !(backend && backend.isRoundLocked) && (model.modelData.black_player_name === "BYE" || model.modelData.white_player_name === "BYE")
                            
                            AppButton {
                                text: "BYE (1 pt)"
                                size: "sm"
                                variant: model.modelData.result === "BYE" ? "success" : "ghost"
                                onClicked: backend.setResult(model.modelData.id, "BYE")
                            }
                        }
                        
                        // Result Display (LOCKED)
                        Text {
                            visible: backend && backend.isRoundLocked
                            text: model.modelData.result === "*" ? "-" : model.modelData.result
                            font.weight: Typography.black
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                            color: Colors.primary
                            Layout.preferredWidth: 160
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        // Black Player
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: ScaleManager.scaleSpacing(Spacing.sm)
                            
                            Text {
                                text: model.modelData.black_player_name
                                font.family: Typography.primary
                                font.weight: model.modelData.result === "0-1" ? Typography.black : Typography.bold
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                                color: model.modelData.result === "0-1" ? Colors.primary : Colors.textPrimary
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                            }
                            
                            Rectangle {
                                width: 12; height: 12; radius: 3
                                color: "#1E293B"
                            }
                        }
                        
                        // Delete Button (Manual Only)
                        IconButton {
                            btnIcon: "×"
                            btnVariant: "danger"
                            btnSize: "sm"
                            visible: backend && backend.isPairingModeManual && !(backend.isRoundLocked)
                            onClicked: backend.deletePairing(model.modelData.id)
                        }
                    }
                }
                
                footer: Item {
                    width: parent.width
                    height: ScaleManager.scaleSize(80)
                    visible: pairingView.count > 0
                    
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ScaleManager.scaleSpacing(Spacing.md)

                        // Finish Round Button - Locks the round
                        AppButton {
                            text: "Finish Round"
                            iconRight: "🔒"
                            variant: "primary" // Changed to primary for distinct action
                            size: "lg"
                            visible: backend && backend.currentTournament && backend.viewingRoundNumber === backend.currentTournament.current_round && !(backend.isRoundLocked)
                            onClicked: {
                                backend.lockRound(backend.viewingRoundNumber)
                                globalToast.show("Round Finished", "Results locked. Ready for next round.", "success")
                            }
                        }

                        // Start Next Round Button - Only visible after locking
                        AppButton {
                            text: "Start Next Round"
                            iconRight: "→"
                            variant: "success"
                            size: "lg"
                            visible: backend && backend.currentTournament && 
                                     backend.viewingRoundNumber === backend.currentTournament.current_round && 
                                     backend.isRoundLocked &&
                                     backend.currentTournament.current_round < backend.currentTournament.total_rounds
                            onClicked: pairingChoiceDialog.open()
                        }
                    }
                }
                
                // Empty State
                Column {
                    visible: pairingView.count === 0 && !(backend && backend.isPairingModeManual)
                    anchors.centerIn: parent
                    spacing: ScaleManager.scaleSpacing(Spacing.lg)
                    
                    Text { text: "⚔"; font.pixelSize: 64; opacity: 0.2; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "No pairings generated yet."; color: Colors.textDisabled; anchors.horizontalCenter: parent.horizontalCenter }
                    AppButton {
                        text: "Generate Pairings"
                        variant: "primary"
                        onClicked: pairingChoiceDialog.open()
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // Unlock Dialog
    Dialog {
        id: unlockDialog
        modal: true
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: ScaleManager.scaleSize(450)
        parent: Overlay.overlay
        
        background: Rectangle {
            color: Colors.surfaceElevated
            radius: ScaleManager.scaleRadius(Spacing.radiusLg)
            border.color: Colors.danger
        }
        
        contentItem: ColumnLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.xl)
            
            Text {
                text: "Unlock Round Results?"
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                font.weight: Typography.bold
                color: Colors.danger
            }

            Text {
                text: "WARNING: Unlocking a past round will temporarily remove its results from standings. Edits will only apply after you re-lock the round."
                font.family: Typography.primary
                color: Colors.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                
                AppButton { text: "Cancel"; variant: "ghost"; onClicked: unlockDialog.close() }
                AppButton { 
                    text: "Unlock Round"; variant: "danger"; 
                    onClicked: {
                        backend.unlockRound(backend.viewingRoundNumber)
                        unlockDialog.close()
                    }
                }
            }
        }
    }

    PairingChoiceDialog {
        id: pairingChoiceDialog
        onAutoSelected: backend.setupNextRound("AUTO")
        onManualSelected: backend.setupNextRound("MANUAL")
    }
}
