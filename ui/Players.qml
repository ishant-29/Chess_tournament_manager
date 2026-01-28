import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"
import "design"

Page {
    title: "Players"
    background: Rectangle { color: "transparent" }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: ScaleManager.scaleSpacing(Spacing.paddingPage)
        spacing: ScaleManager.scaleSpacing(Spacing.xl)
        
        // Player List
        AppCard {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: ScaleManager.scaleSize(400)
            Layout.preferredWidth: ScaleManager.scaleSize(600)
            
            ColumnLayout {
                anchors.fill: parent
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                
                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: ScaleManager.scaleSpacing(Spacing.sm)
                    
                    Text {
                        text: "Players"
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                        font.weight: Typography.bold
                        color: Colors.textPrimary
                    }
                    AppBadge {
                        text: backend ? backend.playerList.length.toString() : "0"
                        variant: "primary"
                        size: "sm"
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Import/Export buttons
                    AppButton {
                        text: "Import"
                        iconLeft: "📥"
                        variant: "ghost"
                        size: "sm"
                        visible: backend && backend.currentTournament && backend.currentTournament.current_round === 0
                        onClicked: {
                            importExportDialog.mode = "import"
                            importExportDialog.open()
                        }
                    }
                    
                    AppButton {
                        text: "Export"
                        iconLeft: "📤"
                        variant: "ghost"
                        size: "sm"
                        visible: backend && backend.playerList.length > 0
                        onClicked: {
                            importExportDialog.mode = "export"
                            importExportDialog.open()
                        }
                    }
                    
                    AppButton {
                        text: "Print"
                        iconLeft: "🖨️"
                        variant: "secondary"
                        size: "sm"
                        visible: backend && backend.playerList.length > 0
                        onClicked: backend.printPlayerList()
                    }
                    

                }

                // List
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: playerView
                        width: parent.width
                        model: backend ? backend.playerList : []
                        spacing: ScaleManager.scaleSpacing(Spacing.sm)
                        
                        delegate: Rectangle {
                            id: playerRow
                            width: parent.width
                            height: ScaleManager.scaleSize(64)
                            color: model.modelData.status === "WITHDRAWN" ? Qt.rgba(Colors.danger.r, Colors.danger.g, Colors.danger.b, 0.05) : (hoverHandler.hovered ? Colors.surfaceHighlight : "transparent")
                            radius: ScaleManager.scaleRadius(Spacing.radiusMd)
                            
                            HoverHandler { id: hoverHandler }
                            
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: contextMenu.popup()
                            }
                            
                            Menu {
                                id: contextMenu
                                MenuItem {
                                    text: "Edit Player"
                                    onTriggered: {
                                        editPlayerDialog.playerId = model.modelData.id
                                        editPlayerDialog.playerName = model.modelData.name
                                        editPlayerDialog.playerClub = model.modelData.club || ""
                                        editPlayerDialog.open()
                                    }
                                }
                                MenuItem {
                                    text: "Withdraw Player"
                                    enabled: model.modelData.status === "ACTIVE"
                                    onTriggered: {
                                        confirmWithdraw.targetId = model.modelData.id
                                        confirmWithdraw.open()
                                    }
                                }
                                MenuItem {
                                    text: "Delete Player"
                                    enabled: backend.currentTournament && (backend.currentTournament.current_round === 0 || model.modelData.status !== "WITHDRAWN")
                                    onTriggered: backend.deletePlayer(model.modelData.id)
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.base)
                                anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.base)
                                anchors.topMargin: ScaleManager.scaleSpacing(Spacing.sm)
                                anchors.bottomMargin: ScaleManager.scaleSpacing(Spacing.sm)
                                spacing: ScaleManager.scaleSpacing(Spacing.base)
                                
                                // Avatar / Initials - Fixed width column
                                Item {
                                    Layout.preferredWidth: ScaleManager.scaleSize(44)
                                    Layout.fillHeight: true
                                    
                                    Rectangle {
                                        width: ScaleManager.scaleSize(40)
                                        height: ScaleManager.scaleSize(40)
                                        anchors.centerIn: parent
                                        radius: width / 2
                                        color: model.modelData.status === "WITHDRAWN" ? Colors.textDisabled : Colors.primary
                                        
                                        layer.enabled: true
                                        layer.effect: Glow {
                                            samples: 10
                                            radius: 4
                                            color: model.modelData.status === "WITHDRAWN" ? "transparent" : Colors.glowPrimary
                                            spread: 0.2
                                        }
                                        
                                        Text {
                                            text: model.modelData.name.charAt(0).toUpperCase()
                                            anchors.centerIn: parent
                                            color: Colors.textOnPrimary
                                            font.weight: Typography.bold
                                            font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                                        }
                                    }
                                }
                                
                                // Name column - Centered vertically within row
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: ScaleManager.scaleSpacing(Spacing.xxs)
                                        
                                        Text { 
                                            text: model.modelData.name
                                            color: model.modelData.status === "WITHDRAWN" ? Colors.textDisabled : Colors.textPrimary
                                            font.family: Typography.primary
                                            font.weight: Typography.bold
                                            font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                                            font.strikeout: model.modelData.status === "WITHDRAWN"
                                        }
                                        
                                        Text { 
                                            text: model.modelData.club ? model.modelData.club : "Independent"
                                            color: Colors.textTertiary
                                            font.family: Typography.primary
                                            font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                                        }
                                    }
                                }
                                
                                // Status Badge
                                AppBadge {
                                    visible: model.modelData.status === "WITHDRAWN"
                                    text: "WITHDRAWN"
                                    variant: "danger"
                                    size: "sm"
                                }
                                
                                // Action Buttons (Visible on hover)
                                Row {
                                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                                    visible: hoverHandler.hovered
                                    
                                    IconButton {
                                        btnIcon: "✏️"
                                        btnVariant: "primary"
                                        btnSize: "md"
                                        btnTooltip: "Edit Player"
                                        onClicked: {
                                            editPlayerDialog.playerId = model.modelData.id
                                            editPlayerDialog.playerName = model.modelData.name
                                            editPlayerDialog.playerClub = model.modelData.club || ""
                                            editPlayerDialog.open()
                                        }
                                    }
                                    
                                    IconButton {
                                        btnIcon: "🚫"
                                        btnVariant: "warning"
                                        btnSize: "md"
                                        btnTooltip: "Withdraw Player"
                                        visible: model.modelData.status === "ACTIVE"
                                        onClicked: {
                                            confirmWithdraw.targetId = model.modelData.id
                                            confirmWithdraw.open()
                                        }
                                    }
                                    
                                    IconButton {
                                        btnIcon: "×"
                                        btnVariant: "danger"
                                        btnSize: "md"
                                        btnTooltip: "Delete Player"
                                        visible: backend && backend.currentTournament && (backend.currentTournament.current_round === 0 || model.modelData.status !== "WITHDRAWN")
                                        onClicked: {
                                            confirmDelete.targetId = model.modelData.id
                                            confirmDelete.open()
                                        }
                                    }
                                }
                            }
                            
                            Behavior on color { ColorAnimation { duration: Animations.fast } }
                        }
                        
                        add: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
                                NumberAnimation { property: "x"; from: -20; to: 0; duration: Animations.normal; easing.type: Animations.easeOutCubic }
                            }
                        }
                        
                        remove: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; to: 0; duration: Animations.normal }
                                NumberAnimation { property: "x"; to: 20; duration: Animations.normal; easing.type: Animations.easeInCubic }
                            }
                        }
                        
                        displaced: Transition {
                            NumberAnimation { properties: "y"; duration: Animations.normal; easing.type: Animations.easeInOutQuad }
                        }
                    }
                }
            }
        }
        
        // Add Player Form
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: ScaleManager.scaleSize(360)
            spacing: ScaleManager.scaleSpacing(Spacing.xl)
            
            AppCard {
                Layout.fillWidth: true
                Layout.preferredHeight: contentColumn.implicitHeight + ScaleManager.scaleSpacing(Spacing.paddingCard) * 2
                
                ColumnLayout {
                    id: contentColumn
                    anchors.fill: parent
                    spacing: ScaleManager.scaleSpacing(Spacing.xl)
                    
                    Text {
                        text: "Add New Player"
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                        font.weight: Typography.bold
                        color: Colors.textPrimary
                    }
                    
                    AppTextField {
                        id: pName
                        label: "Full Name"
                        placeholderText: "e.g. Viswanathan Anand"
                        Layout.fillWidth: true
                        iconPrefix: "👤"
                        onAccepted: addButton.clicked()
                    }
                    
                    AppTextField {
                        id: pClub
                        label: "Club / City (Optional)"
                        placeholderText: "e.g. Chennai Chess Academy"
                        Layout.fillWidth: true
                        iconPrefix: "🏢"
                        onAccepted: addButton.clicked()
                    }
                    
                    AppButton {
                        id: addButton
                        text: "Add Player"
                        iconLeft: "+"
                        Layout.fillWidth: true
                        variant: "primary"
                        onClicked: {
                            if(pName.text !== "") {
                                backend.addPlayer(pName.text, 0, "", pClub.text)
                                pName.text = ""
                                pClub.text = ""
                                pName.forceActiveFocus()
                                globalToast.show("Player Added", "Successfully registered to tournament", "success")
                            }
                        }
                    }
                }
            }
            
            // Next Steps / Action Card
            AppCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                hasGradient: backend && backend.playerList.length >= 2
                
                ColumnLayout {
                    anchors.fill: parent
                    spacing: ScaleManager.scaleSpacing(Spacing.lg)
                    
                    Text {
                        text: "Tournament Actions"
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.h4)
                        font.weight: Typography.bold
                        color: Colors.textPrimary
                    }
                    
                    Text {
                        text: {
                            if (!backend || !backend.currentTournament) return ""
                            if (backend.playerList.length < 2) return "Add at least 2 players to start the tournament."
                            if (backend.currentTournament.current_round >= backend.currentTournament.total_rounds) return "Tournament Complete. View Standings for final results."
                            return "Player registration complete. Ready to generate pairings for the next round."
                        }
                        color: Colors.textSecondary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                    
                    Item { Layout.preferredHeight: ScaleManager.scaleSize(Spacing.md) }
                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScaleManager.scaleSpacing(Spacing.md)
                        
                        AppButton {
                            text: "Edit Tournament"
                            iconLeft: "✏️"
                            Layout.fillWidth: true
                            variant: "secondary"
                            onClicked: editTournamentDialog.open()
                        }
                        
                        AppButton {
                            text: "Start Round " + (backend && backend.currentTournament ? (backend.currentTournament.current_round + 1) : "1")
                            iconRight: "→"
                            Layout.fillWidth: true
                            size: "lg"
                            visible: backend && backend.currentTournament && backend.currentTournament.current_round < backend.currentTournament.total_rounds
                            enabled: backend && backend.playerList.length >= 2
                            variant: "success"
                            onClicked: pairingChoiceDialog.open()
                        }
                    }
                }
            }
        }
    }
    
    // Withdraw Dialog
    Dialog {
        id: confirmWithdraw
        property int targetId: -1
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: ScaleManager.scaleSize(400)
        modal: true
        parent: Overlay.overlay
        
        background: Rectangle {
            color: Colors.surfaceElevated
            radius: ScaleManager.scaleRadius(Spacing.radiusLg)
            border.color: Colors.warning
            border.width: Spacing.borderThin
            
            layer.enabled: true
            layer.effect: DropShadow {
                radius: 20
                samples: 30
                color: Colors.shadowDark
                verticalOffset: 4
            }
        }
        
        contentItem: ColumnLayout {
            spacing: ScaleManager.scaleSpacing(Spacing.xl)
            
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                Text { text: "🚫"; font.pixelSize: ScaleManager.scaleFontSize(32) }
                Text { 
                    text: "Withdraw Player?" 
                    color: Colors.textPrimary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                    font.weight: Typography.bold
                }
            }
            
            Text { 
                text: "This player will be excluded from all future pairings. This action is usually performed if a player leaves the tournament early." 
                color: Colors.textSecondary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                
                AppButton {
                    text: "Cancel"
                    variant: "ghost"
                    onClicked: confirmWithdraw.close()
                }
                
                AppButton {
                    text: "Confirm Withdrawal"
                    variant: "warning"
                    onClicked: {
                        if(confirmWithdraw.targetId !== -1) {
                            backend.withdrawPlayer(confirmWithdraw.targetId)
                            confirmWithdraw.close()
                            globalToast.show("Player Withdrawn", "Status updated successfully", "warning")
                        }
                    }
                }
            }
        }
        
        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: Animations.normal; easing.type: Animations.easeOutBack }
        }
    }

    PairingChoiceDialog {
        id: pairingChoiceDialog
        onAutoSelected: {
            backend.setupNextRound("AUTO")
            stackView.push("Pairings.qml")
        }
        onManualSelected: {
             backend.setupNextRound("MANUAL")
             stackView.push("Pairings.qml")
        }
    }
    
    // Edit Player Dialog
    EditPlayerDialog {
        id: editPlayerDialog
    }
    
    // Import/Export
    ImportExportDialog {
        id: importExportDialog
    }
    
    // Delete Confirmation
    ConfirmDialog {
        id: confirmDelete
        property int targetId: -1
        dialogTitle: "Delete Player?"
        dialogMessage: "This will permanently remove the player from this tournament. This action cannot be undone."
        confirmText: "Delete"
        variant: "danger"
        iconText: "×"
        onConfirmed: {
            if (targetId !== -1) {
                backend.deletePlayer(targetId)
            }
        }
    }
    
    // Edit Tournament
    EditTournamentDialog {
        id: editTournamentDialog
    }
}
