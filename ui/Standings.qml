import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "components"
import "design"

Page {
    title: "Standings"
    background: Rectangle { color: "transparent" }
    
    onVisibleChanged: {
        if(visible) {
            backend.updateStandings()
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScaleManager.scaleSpacing(Spacing.paddingPage)
        spacing: ScaleManager.scaleSpacing(Spacing.xl)
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.lg)
            
            Column {
                spacing: ScaleManager.scaleSpacing(Spacing.xs)
                Text {
                    text: "Tournament Standings"
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.h1)
                    font.weight: Typography.black
                    color: Colors.textPrimary
                }
                Text {
                    text: "Current rankings after " + (backend && backend.currentTournament ? backend.currentTournament.current_round : "0") + " rounds"
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                    color: Colors.textTertiary
                }
            }
            
            Item { Layout.fillWidth: true }
            
            AppButton {
                text: "Refresh"
                variant: "ghost"
                iconLeft: "↻"
                onClicked: backend.updateStandings()
            }
            
            AppButton {
                text: "Export PDF"
                variant: "primary"
                iconLeft: "📄"
                onClicked: backend.printStandingsReport()
            }
        }
        
        // Standings Table
        AppCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                
                // Table Header
                Rectangle {
                    Layout.fillWidth: true
                    height: ScaleManager.scaleSize(48)
                    color: Colors.surfaceHighlight
                    radius: ScaleManager.scaleRadius(Spacing.radiusLg)
                    // Round top corners only
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: parent.width
                            height: parent.height
                            radius: ScaleManager.scaleRadius(Spacing.radiusLg)
                        }
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.xl)
                        anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.xl)
                        spacing: ScaleManager.scaleSpacing(Spacing.base)
                        
                        Text { text: "#"; color: Colors.textTertiary; font.weight: Typography.bold; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignHCenter }
                        Text { text: "Player Name"; color: Colors.textTertiary; font.weight: Typography.bold; Layout.fillWidth: true }
                        Text { text: "Points"; color: Colors.textTertiary; font.weight: Typography.bold; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                    }
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: standingsView
                        width: parent.width
                        model: backend ? backend.standingsList : []
                        spacing: 0
                        
                        delegate: Rectangle {
                            width: parent.width
                            height: ScaleManager.scaleSize(56)
                            color: hoverHandler.hovered ? Colors.surfaceHighlight : "transparent"
                            
                            HoverHandler { id: hoverHandler }
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: ScaleManager.scaleSpacing(Spacing.xl)
                                anchors.rightMargin: ScaleManager.scaleSpacing(Spacing.xl)
                                spacing: ScaleManager.scaleSpacing(Spacing.base)
                                
                                // Rank
                                Item {
                                    Layout.preferredWidth: 40
                                    height: parent.height
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: ScaleManager.scaleSize(28)
                                        height: ScaleManager.scaleSize(28)
                                        radius: 14
                                        color: index === 0 ? "#FBBF24" : (index === 1 ? "#94A3B8" : (index === 2 ? "#B45309" : "transparent"))
                                        visible: index < 3
                                        
                                        layer.enabled: index === 0
                                        layer.effect: Glow {
                                            samples: 15; radius: 8; color: "#40FBBF24"; spread: 0.2
                                        }
                                    }
                                    
                                    Text {
                                        text: index + 1
                                        anchors.centerIn: parent
                                        color: index < 3 ? "#FFFFFF" : Colors.textTertiary
                                        font.weight: index < 3 ? Typography.black : Typography.bold
                                        font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                                    }
                                }
                                
                                // Player Name
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: ScaleManager.scaleSpacing(Spacing.md)
                                    
                                    Rectangle {
                                        width: ScaleManager.scaleSize(32)
                                        height: ScaleManager.scaleSize(32)
                                        radius: 16
                                        color: index < 3 ? Colors.primary : Colors.surfaceHighlight
                                        Text {
                                            text: model.modelData.name.charAt(0).toUpperCase()
                                            anchors.centerIn: parent
                                            color: index < 3 ? Colors.textOnPrimary : Colors.textSecondary
                                            font.weight: Typography.bold
                                        }
                                    }
                                    
                                    Text { 
                                        text: model.modelData.name
                                        color: Colors.textPrimary
                                        font.family: Typography.primary
                                        font.weight: index < 3 ? Typography.black : Typography.bold
                                        font.pixelSize: ScaleManager.scaleFontSize(Typography.bodyLarge)
                                        Layout.fillWidth: true 
                                        elide: Text.ElideRight
                                    }
                                }
                                
                                // Points
                                Text { 
                                    text: model.modelData.points
                                    color: Colors.primary
                                    font.family: Typography.primary
                                    font.pixelSize: ScaleManager.scaleFontSize(Typography.h4)
                                    font.weight: Typography.black
                                    Layout.preferredWidth: 80
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                

                            }
                            
                            // Separator
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Colors.border
                                opacity: 0.5
                                visible: index < standingsView.count - 1
                            }
                            
                            Behavior on color { ColorAnimation { duration: Animations.fast } }
                        }
                        
                        add: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Animations.slow; easing.type: Animations.easeOutSine }
                                NumberAnimation { property: "y"; from: 20; to: 0; duration: Animations.slow; easing.type: Animations.easeOutCubic }
                            }
                        }
                        
                        displaced: Transition {
                            NumberAnimation { properties: "y"; duration: Animations.normal; easing.type: Animations.easeInOutQuad }
                        }
                    }
                }
            }
        }
    }
}
