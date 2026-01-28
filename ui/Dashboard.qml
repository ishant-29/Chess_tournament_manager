import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"
import "design"

Page {
    title: "Tournament Library"
    background: Rectangle { color: "transparent" }
    
    // Properties for filtering
    property string searchText: ""
    property string filterType: "All"
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScaleManager.scaleSize(120)
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.1) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: ScaleManager.scaleSpacing(Spacing.paddingPage)
                spacing: ScaleManager.scaleSpacing(Spacing.xl)
                
                Column {
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    Layout.fillWidth: true
                    
                    Text {
                        text: "My Tournaments"
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.h1)
                        font.weight: Typography.black
                        color: Colors.textPrimary
                    }
                    
                    Text {
                        text: "Manage and organize your chess tournaments"
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                        color: Colors.textSecondary
                    }
                }
                
                AppButton {
                    text: "New Tournament"
                    iconLeft: "+"
                    size: "lg"
                    variant: "primary"
                    onClicked: createDialog.open()
                }
            }
        }
        
        // Filters
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScaleManager.scaleSize(80)
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.paddingPage)
                anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.paddingPage)
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                
                // Search Bar
                AppTextField {
                    id: searchField
                    placeholderText: "Search tournaments..."
                    iconPrefix: "🔍"
                    showClearButton: true
                    Layout.preferredWidth: ScaleManager.scaleSize(360)
                    onTextChanged: searchText = text
                }
                
                // Filters
                Row {
                    spacing: ScaleManager.scaleSpacing(Spacing.sm)
                    
                    Repeater {
                        model: ["All", "SWISS", "ROUND_ROBIN"]
                        delegate: Button {
                            text: modelData === "All" ? "All" : (modelData === "SWISS" ? "Swiss" : "Round Robin")
                            
                            contentItem: Text {
                                text: parent.text
                                color: filterType === modelData ? Colors.textOnPrimary : Colors.textSecondary
                                font.family: Typography.primary
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                                font.weight: Typography.semibold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            background: Rectangle {
                                implicitWidth: ScaleManager.scaleSize(100)
                                implicitHeight: ScaleManager.scaleSize(36)
                                color: filterType === modelData ? Colors.primary : Colors.surfaceHighlight
                                radius: ScaleManager.scaleRadius(Spacing.radiusFull)
                                
                                Behavior on color { ColorAnimation { duration: Animations.fast } }
                            }
                            
                            HoverHandler {
                                cursorShape: Qt.PointingHandCursor
                            }
                            
                            onClicked: filterType = modelData
                        }
                    }
                }
                
                Item { Layout.fillWidth: true }
            }
        }
        
        // Grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            
            // Empty State
            Column {
                visible: grid.count === 0
                anchors.centerIn: parent
                spacing: ScaleManager.scaleSpacing(Spacing.xl)
                
                Text {
                    text: "📋"
                    font.pixelSize: ScaleManager.scaleFontSize(64)
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.5
                }
                
                Column {
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    
                    Text {
                        text: "No tournaments found"
                        color: Colors.textPrimary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                        font.weight: Typography.semibold
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "Create your first tournament to get started"
                        color: Colors.textSecondary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                
                AppButton {
                    text: "Create Tournament"
                    variant: "primary"
                    iconLeft: "+"
                    onClicked: createDialog.open()
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            
            Flow {
                width: parent.width
                spacing: ScaleManager.scaleSpacing(Spacing.lg)
                padding: ScaleManager.scaleSpacing(Spacing.paddingPage)
                
                Repeater {
                    id: grid
                    model: backend ? backend.recentTournaments : []
                    
                    delegate: Item {
                        property bool matchesSearch: model.modelData.name.toLowerCase().includes(searchText.toLowerCase())
                        property bool matchesType: filterType === "All" || model.modelData.type === filterType
                        visible: matchesSearch && matchesType
                        
                        width: visible ? card.width : 0
                        height: visible ? card.height : 0
                        
                        TournamentCard {
                            id: card
                            visible: parent.visible
                            
                            tName: model.modelData.name
                            tType: model.modelData.type
                            tStatus: model.modelData.status
                            tDate: model.modelData.date
                            tCurrentRound: model.modelData.current_round
                            tTotalRounds: model.modelData.total_rounds
                            tId: model.modelData.id
                            tVenue: model.modelData.venue || ""
                            
                            onCardClicked: {
                                console.log("Card clicked, loading tournament ID:", tid)
                                backend.loadTournament(tid)
                                
                                var obj = parent
                                while (obj) {
                                    if (obj.objectName === "mainStackView") {
                                        obj.push("Players.qml")
                                        return
                                    }
                                    obj = obj.parent
                                }
                                console.error("Could not find stackView!")
                            }
                            
                            onDeleteClicked: {
                                confirmDeleteDialog.targetId = tid
                                confirmDeleteDialog.open()
                            }
                            
                            onCloneClicked: {
                                cloneDialog.sourceTid = tid
                                cloneName.text = "Copy of " + tName
                                cloneVenue.text = tVenue
                                cloneRounds.value = tTotalRounds
                                cloneDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // CreateDialog
    Dialog {
        id: createDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: ScaleManager.scaleSize(480)
        modal: true
        parent: Overlay.overlay
        
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
            
            // Dialog Title
            Text {
                text: "Create Tournament"
                color: Colors.textPrimary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
                font.weight: Typography.bold
            }
            
            // Name Field
            AppTextField {
                id: newName
                label: "Tournament Name"
                placeholderText: "Enter tournament name"
                Layout.fillWidth: true
            }

            // Venue Field
            AppTextField {
                id: newVenue
                label: "Venue"
                placeholderText: "e.g. Grand Hall, City Center"
                Layout.fillWidth: true
                iconPrefix: "📍"
            }
            
            // Format and Rounds Row
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                Layout.fillWidth: true
                
                ColumnLayout {
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Format"
                        color: Colors.textSecondary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                        font.weight: Typography.medium
                    }
                    
                    ComboBox {
                        id: newType
                        model: ["SWISS", "ROUND_ROBIN"]
                        Layout.fillWidth: true
                        
                        background: Rectangle {
                            color: Colors.background
                            radius: ScaleManager.scaleRadius(Spacing.radiusMd)
                            border.color: Colors.border
                            border.width: Spacing.borderNormal
                        }
                        
                        contentItem: Text {
                            text: newType.displayText
                            color: Colors.textPrimary
                            font.family: Typography.primary
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                            leftPadding: ScaleManager.scaleSpacing(Spacing.base)
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
                
                ColumnLayout {
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Rounds"
                        color: Colors.textSecondary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                        font.weight: Typography.medium
                    }
                    
                    SpinBox {
                        id: newRounds
                        from: 1
                        to: 20
                        value: 5
                        Layout.fillWidth: true
                        editable: true
                        
                        palette.base: Colors.background
                        palette.text: Colors.textPrimary
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
                    onClicked: createDialog.close()
                }
                
                AppButton {
                    text: "Create"
                    variant: "primary"
                    iconLeft: "+"
                    onClicked: {
                        if (newName.text !== "") {
                            backend.createTournament(newName.text, newType.currentText, newRounds.value, newVenue.text)
                            createDialog.close()
                            newName.text = ""
                            newVenue.text = ""
                        }
                    }
                }
            }
        }
        
        // Enter animation
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

    // CloneDialog
    Dialog {
        id: cloneDialog
        property int sourceTid: -1
        
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: ScaleManager.scaleSize(480)
        modal: true
        parent: Overlay.overlay
        
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
            
            // Dialog Title
            Text {
                text: "Clone Tournament"
                color: Colors.textPrimary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
                font.weight: Typography.bold
            }
            
            Text {
                text: "Cloning will copy settings and players, but reset all scores and pairings."
                color: Colors.textSecondary
                font.family: Typography.primary
                font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            // Name Field
            AppTextField {
                id: cloneName
                label: "New Tournament Name"
                placeholderText: "Enter tournament name"
                Layout.fillWidth: true
            }

            // Venue Field
            AppTextField {
                id: cloneVenue
                label: "Venue"
                placeholderText: "Venue"
                Layout.fillWidth: true
                iconPrefix: "📍"
            }
            
            // Format and Rounds Row
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.base)
                Layout.fillWidth: true
                
                ColumnLayout {
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    Layout.fillWidth: true
                    
                    Label {
                        text: "Rounds"
                        color: Colors.textSecondary
                        font.family: Typography.primary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                        font.weight: Typography.medium
                    }
                    
                    SpinBox {
                        id: cloneRounds
                        from: 1
                        to: 20
                        value: 5
                        Layout.fillWidth: true
                        editable: true
                        
                        palette.base: Colors.background
                        palette.text: Colors.textPrimary
                    }
                }
                Item { Layout.fillWidth: true }
            }
            
            // Actions
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                Layout.alignment: Qt.AlignRight
                
                AppButton {
                    text: "Cancel"
                    variant: "ghost"
                    onClicked: cloneDialog.close()
                }
                
                AppButton {
                    text: "Clone"
                    variant: "primary"
                    iconLeft: "📋"
                    onClicked: {
                        if (cloneName.text !== "" && cloneDialog.sourceTid !== -1) {
                            backend.cloneTournament(cloneDialog.sourceTid, cloneName.text, cloneVenue.text, cloneRounds.value)
                            cloneDialog.close()
                        }
                    }
                }
            }
        }
        
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: Animations.slow; easing.type: Animations.easeOutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.slow }
            }
        }
    }
    
    // DeleteDialog
    Dialog {
        id: confirmDeleteDialog
        property int targetId: -1
        
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: ScaleManager.scaleSize(420)
        modal: true
        parent: Overlay.overlay
        
        background: Rectangle {
            color: Colors.surfaceElevated
            radius: ScaleManager.scaleRadius(Spacing.radiusLg)
            border.color: Colors.danger
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
            
            // Warning Icon & Title
            RowLayout {
                spacing: ScaleManager.scaleSpacing(Spacing.md)
                
                Text {
                    text: "⚠"
                    font.pixelSize: ScaleManager.scaleFontSize(32)
                    color: Colors.danger
                }
                
                Text {
                    text: "Delete Tournament?"
                    color: Colors.textPrimary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.h3)
                    font.weight: Typography.bold
                }
            }
            
            // Warning Message
            Text {
                text: "This action cannot be undone. All players, pairings, and results will be permanently lost."
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
                    text: "Cancel"
                    variant: "ghost"
                    onClicked: confirmDeleteDialog.close()
                }
                
                AppButton {
                    text: "Delete Forever"
                    variant: "danger"
                    iconLeft: "×"
                    onClicked: {
                        if (confirmDeleteDialog.targetId !== -1) {
                            backend.deleteTournament(confirmDeleteDialog.targetId)
                            confirmDeleteDialog.close()
                        }
                    }
                }
            }
        }
    }
}

