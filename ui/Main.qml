import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"
import "design"

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    title: "Chess Tournament Manager"
    color: Colors.background
    
    // Zoom shortcuts
    Shortcut {
        sequence: "Ctrl++"
        onActivated: ScaleManager.zoomIn()
    }
    
    Shortcut {
        sequence: "Ctrl+-"
        onActivated: ScaleManager.zoomOut()
    }
    
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: ScaleManager.resetZoom()
    }
    
    // Ctrl+Z Undo
    Shortcut {
        sequence: "Ctrl+Z"
        onActivated: {
            if (backend && backend.canUndo) {
                backend.undo()
            }
        }
    }
    
    // Layout
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // --- Sidebar ---
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: ScaleManager.scaleSize(Spacing.sidebarWidthExpanded)
            
            gradient: Colors.sidebarGradient()
            
            ColumnLayout {
                anchors.fill: parent
                spacing: ScaleManager.scaleSpacing(Spacing.sm)
                
                // Logo / Title Area
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScaleManager.scaleSize(80)
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: ScaleManager.scaleSpacing(Spacing.xs)
                        
                        Text {
                            text: "♟"
                            color: Colors.primary // Soft Primary for logo
                            font.pixelSize: ScaleManager.scaleFontSize(32)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "CHESS MANAGER"
                            color: Colors.textPrimary // Dark text
                            font.family: Typography.primary
                            font.weight: Typography.black
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                            font.letterSpacing: Typography.letterSpacingWide
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // Navigation
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: ScaleManager.scaleSpacing(Spacing.base)
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    
                    SidebarItem {
                        Layout.fillWidth: true
                        itemLabel: "Dashboard"
                        itemIcon: "⊞"
                        itemActive: stackView.currentItem && stackView.currentItem.title === "Tournament Library"
                        onClicked: stackView.push("Dashboard.qml")
                    }
                    
                    // Separator
                    Rectangle { 
                        Layout.fillWidth: true
                        height: 1
                        color: Colors.border
                        Layout.topMargin: ScaleManager.scaleSpacing(Spacing.sm)
                        Layout.bottomMargin: ScaleManager.scaleSpacing(Spacing.sm)
                    }
                    
                    Label {
                        text: "TOURNAMENT"
                        color: Colors.textTertiary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                        font.weight: Typography.bold
                        font.letterSpacing: Typography.letterSpacingWider
                        Layout.leftMargin: ScaleManager.scaleSpacing(Spacing.sm)
                    }

                    SidebarItem {
                        Layout.fillWidth: true
                        itemLabel: "Players"
                        itemIcon: "👤"
                        itemActive: stackView.currentItem && stackView.currentItem.title === "Players"
                        onClicked: stackView.push("Players.qml")
                        enabled: backend && backend.currentTournament !== null
                        opacity: enabled ? 1.0 : 0.5
                    }
                    
                    SidebarItem {
                        Layout.fillWidth: true
                        itemLabel: "Pairings"
                        itemIcon: "⚔"
                        itemActive: stackView.currentItem && stackView.currentItem.title === "Pairings"
                        onClicked: stackView.push("Pairings.qml")
                        enabled: backend && backend.currentTournament !== null
                        opacity: enabled ? 1.0 : 0.5
                    }
                    
                    SidebarItem {
                        Layout.fillWidth: true
                        itemLabel: "Standings"
                        itemIcon: "🏆"
                        itemActive: stackView.currentItem && stackView.currentItem.title === "Standings"
                        onClicked: stackView.push("Standings.qml")
                        enabled: backend && backend.currentTournament !== null
                        opacity: enabled ? 1.0 : 0.5
                    }
                }
                
                Item { Layout.fillHeight: true }
                
                // Zoom Controls
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: ScaleManager.scaleSpacing(Spacing.base)
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    
                    Label {
                        text: "ZOOM"
                        color: Colors.textTertiary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                        font.weight: Typography.bold
                        font.letterSpacing: Typography.letterSpacingWider
                    }
                    
                    Row {
                        spacing: ScaleManager.scaleSpacing(Spacing.xs)
                        
                        IconButton {
                            btnIcon: "−"
                            btnSize: "sm"
                            btnTooltip: "Zoom Out (Ctrl + -)"
                            onClicked: ScaleManager.zoomOut()
                        }
                        
                        Label {
                            text: ScaleManager.getUIScalePercentage() + "%"
                            color: Colors.textPrimary
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                            font.weight: Typography.semibold
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignHCenter
                            width: ScaleManager.scaleSize(50)
                        }
                        
                        IconButton {
                            btnIcon: "+"
                            btnSize: "sm"
                            btnTooltip: "Zoom In (Ctrl + +)"
                            onClicked: ScaleManager.zoomIn()
                        }
                        
                        IconButton {
                            btnIcon: "↻"
                            btnSize: "sm"
                            btnTooltip: "Reset (Ctrl + 0)"
                            onClicked: ScaleManager.resetZoom()
                        }
                    }
                }
                
                // Bottom Info
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: ScaleManager.scaleSpacing(Spacing.base)
                    spacing: ScaleManager.scaleSpacing(Spacing.xs)
                    
                    Label {
                        text: "Active Tournament"
                        color: Colors.textTertiary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                    }
                    Label {
                        text: backend && backend.currentTournament ? backend.currentTournament.name : "None"
                        color: Colors.textPrimary
                        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                        font.weight: Typography.semibold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                // Footer Credit
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: footerCol.implicitHeight + ScaleManager.scaleSpacing(Spacing.base)
                    color: "transparent"
                    
                    Column {
                        id: footerCol
                        anchors.centerIn: parent
                        width: parent.width - ScaleManager.scaleSpacing(Spacing.base) * 2
                        spacing: ScaleManager.scaleSpacing(2)
                        
                        Text {
                            textFormat: Text.RichText
                            text: "Developed with <font color='#FF0000'>❤</font> by<br>Ishant Bishnoi"
                            color: Colors.textTertiary
                            font.family: Typography.primary
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Text {
                            text: "bishnoiishu00@gmail.com"
                            color: Colors.textTertiary
                            font.family: Typography.primary
                            font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.8
                            width: parent.width
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
            
            // Border Line
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Colors.border
            }
        }
        
        // Content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.background
            clip: true
            
            StackView {
                id: stackView
                objectName: "mainStackView"
                anchors.fill: parent
                initialItem: "Dashboard.qml"
                
                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
                        NumberAnimation { property: "y"; from: 10; to: 0; duration: Animations.normal; easing.type: Animations.easeOutQuad }
                    }
                }
                replaceExit: Transition {
                     NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Animations.normal }
                }
                pushEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
                        NumberAnimation { property: "x"; from: 20; to: 0; duration: Animations.normal; easing.type: Animations.easeOutQuad }
                    }
                }
                pushExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Animations.normal }
                }
                popEnter: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.normal }
                }
                popExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Animations.normal }
                        NumberAnimation { property: "x"; from: 0; to: 20; duration: Animations.normal; easing.type: Animations.easeInQuad }
                    }
                }
            }
        }
    }
    
    // Notifications
    AppToast {
        id: globalToast
        parent: Overlay.overlay
    }
    

    Connections {
        target: backend
        function onNotification(title, message) {
            globalToast.show(title, message, "info")
        }
    }
}
