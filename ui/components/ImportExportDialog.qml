import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3 as Dialogs
import QtGraphicalEffects 1.15
import "../design"

Dialog {
    id: importExportDialog
    
    // Mode: "import" or "export"
    property string mode: "import"
    property var previewData: []
    
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0
    width: ScaleManager.scaleSize(550)
    height: ScaleManager.scaleSize(500)
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape
    
    onOpened: {
        previewData = []
        filePathField.text = ""
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
    
    Dialogs.FileDialog {
        id: fileDialog
        title: mode === "import" ? "Select CSV File" : "Save CSV File"
        nameFilters: ["CSV files (*.csv)"]
        selectExisting: mode === "import"
        selectFolder: false
        onAccepted: {
            var path = fileUrl.toString().replace("file:///", "")
            filePathField.text = path
            
            if (mode === "import") {
                previewData = backend.previewImportCSV(path)
            }
        }
    }
    
    contentItem: ColumnLayout {
        spacing: ScaleManager.scaleSpacing(Spacing.lg)
        
        // Header
        Text {
            text: mode === "import" ? "📥 Import Players" : "📤 Export Players"
            color: Colors.textPrimary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.h2)
            font.weight: Typography.bold
        }
        
        Text {
            text: mode === "import" 
                ? "Import players from a CSV file. Format: Name, Club, Rating"
                : "Export current player list to a CSV file."
            color: Colors.textSecondary
            font.family: Typography.primary
            font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        
        // File Path
        RowLayout {
            Layout.fillWidth: true
            spacing: ScaleManager.scaleSpacing(Spacing.sm)
            
            AppTextField {
                id: filePathField
                label: "File Path"
                placeholderText: mode === "import" ? "Select a CSV file..." : "Choose save location..."
                Layout.fillWidth: true
                readOnly: true
            }
            
            AppButton {
                text: "Browse"
                variant: "secondary"
                onClicked: fileDialog.open()
            }
        }
        
        // Preview (Import only)
        Rectangle {
            visible: mode === "import" && previewData.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.background
            radius: ScaleManager.scaleRadius(Spacing.radiusMd)
            border.color: Colors.border
            border.width: 1
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScaleManager.scaleSpacing(Spacing.md)
                spacing: ScaleManager.scaleSpacing(Spacing.sm)
                
                Text {
                    text: "Preview (" + previewData.length + " players)"
                    color: Colors.textSecondary
                    font.family: Typography.primary
                    font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                    font.weight: Typography.semibold
                }
                
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: previewData
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: ScaleManager.scaleSize(36)
                        color: modelData.duplicate ? Qt.rgba(Colors.warning.r, Colors.warning.g, Colors.warning.b, 0.1) : "transparent"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: ScaleManager.scaleSpacing(Spacing.sm)
                            
                            Text {
                                text: modelData.name
                                color: modelData.duplicate ? Colors.warning : Colors.textPrimary
                                font.family: Typography.primary
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.body)
                                Layout.fillWidth: true
                            }
                            
                            Text {
                                text: modelData.club || "—"
                                color: Colors.textTertiary
                                font.family: Typography.primary
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.small)
                            }
                            
                            Text {
                                visible: modelData.duplicate
                                text: "⚠ Duplicate"
                                color: Colors.warning
                                font.family: Typography.primary
                                font.pixelSize: ScaleManager.scaleFontSize(Typography.tiny)
                            }
                        }
                    }
                }
            }
        }
        
        // Spacer for export mode
        Item {
            visible: mode === "export"
            Layout.fillHeight: true
        }
        
        // Actions
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: ScaleManager.scaleSpacing(Spacing.md)
            
            AppButton {
                text: "Cancel"
                variant: "ghost"
                onClicked: importExportDialog.close()
            }
            
            AppButton {
                text: mode === "import" ? "Import" : "Export"
                variant: "primary"
                iconLeft: mode === "import" ? "📥" : "📤"
                enabled: filePathField.text !== ""
                onClicked: {
                    if (mode === "import") {
                        backend.importPlayersCSV(filePathField.text)
                    } else {
                        backend.exportPlayersCSV(filePathField.text)
                    }
                    importExportDialog.close()
                }
            }
        }
    }
}
