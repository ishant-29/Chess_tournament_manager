import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
import "../design"

AppCard {
    id: card
    width: Math.max(ScaleManager.scaleSize(320), titleText.implicitWidth + ScaleManager.scaleSpacing(Spacing.xl2))
    height: ScaleManager.scaleSize(200)
    hoverable: true
    hasGradient: tStatus === "ACTIVE"
    
    // Properties
    property string tName: "Unknown"
    property string tType: "SWISS"
    property string tStatus: "SETUP"
    property string tDate: "2023-01-01"
    property int tCurrentRound: 0
    property int tTotalRounds: 5
    property int tId: -1
    property string tVenue: ""
    
    signal cardClicked(int tid)
    signal deleteClicked(int tid)
    signal cloneClicked(int tid)
    
    onClicked: {
        console.log("TournamentCard clicked! ID:", tId)
        card.cardClicked(tId)
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: ScaleManager.scaleSpacing(Spacing.md)
        
        // Header
        RowLayout {
            Layout.fillWidth: true
            
            // Type Badge
            AppBadge {
                text: tType === "SWISS" ? "SWISS" : "RR"
                variant: tType === "SWISS" ? "primary" : "warning"
                size: "sm"
            }
            
            Item { Layout.fillWidth: true }
            
            // Status with dot indicator
            AppBadge {
                text: tStatus
                variant: getStatusVariant()
                showDot: tStatus === "ACTIVE"
                pulse: tStatus === "ACTIVE"
                size: "sm"
            }
        }
        
        // Title
        Text {
            id: titleText
            text: tName
            color: Colors.textPrimary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.h4)
            font.weight: Typography.bold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        
        // Date and Venue
        RowLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            Row {
                spacing: ScaleManager.scaleSpacing(Spacing.xs)
                Text { text: "📅"; font.pixelSize: ScaleManager.scaleFontSize(Typography.small) }
                Text {
                    text: tDate.split(' ')[0]
                    color: Colors.textTertiary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                }
            }
            
            Row {
                spacing: ScaleManager.scaleSpacing(Spacing.xs)
                visible: tVenue !== ""
                Text { text: "📍"; font.pixelSize: ScaleManager.scaleFontSize(Typography.small) }
                Text {
                    text: tVenue
                    color: Colors.textTertiary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
        
        Item { Layout.fillHeight: true }
        
        // Progress
        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.xs)
            
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Progress"
                    color: Colors.textSecondary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: tCurrentRound + "/" + tTotalRounds
                    color: Colors.textPrimary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                    font.weight: Typography.semibold
                }
            }
            
            ProgressIndicator {
                Layout.fillWidth: true
                value: tCurrentRound / Math.max(tTotalRounds, 1)
                variant: tStatus === "ACTIVE" ? "primary" : "default"
                hasGradient: tStatus === "ACTIVE"
                showPercentage: false
            }
        }
    }
    
    // Quick Actions (Hover Only)
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ScaleManager.scaleSpacing(Spacing.sm)
        spacing: ScaleManager.scaleSpacing(Spacing.xs)
        z: 10
        visible: card.hovered
        
        IconButton {
            btnIcon: "📋"
            btnVariant: "secondary"
            btnSize: "md"
            btnTooltip: "Clone Tournament"
            onClicked: {
                console.log("Clone button clicked for ID:", tId)
                card.cloneClicked(tId)
            }
        }

        IconButton {
            btnIcon: "×"
            btnVariant: "danger"
            btnSize: "md"
            btnTooltip: "Delete Tournament"
            onClicked: {
                console.log("Delete button clicked for ID:", tId)
                card.deleteClicked(tId)
            }
        }
    }
    
    // Helper Functions
    function getStatusVariant() {
        switch(tStatus) {
            case "ACTIVE": return "success"
            case "FINISHED": return "neutral"
            case "COMPLETED": return "neutral"
            case "SETUP": return "warning"
            default: return "neutral"
        }
    }
}
