import QtQuick 2.15
import QtGraphicalEffects 1.15
import "../design"

Item {
    id: root
    default property alias content: container.children
    property alias color: bg.color
    property bool hoverable: false
    property alias radius: bg.radius
    property bool hasGradient: false
    implicitWidth: container.implicitWidth + (ScaleManager.scaleSpacing(Spacing.paddingCard) * 2)
    implicitHeight: container.implicitHeight + (ScaleManager.scaleSpacing(Spacing.paddingCard) * 2)
    
    readonly property bool hovered: hoverHandler.hovered
    
    signal clicked()
    
    // Hover lift effect
    transform: Translate {
        id: hoverTransform
        y: 0
    }
    
    Rectangle {
        id: bg
        anchors.fill: parent
        color: Colors.surfaceElevated
        radius: ScaleManager.scaleRadius(Spacing.radiusMd)
        
        // Gradient overlay (optional)
        Rectangle {
            visible: hasGradient
            anchors.fill: parent
            radius: parent.radius
            opacity: 0.1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Colors.primaryLight }
                GradientStop { position: 1.0; color: Colors.accentLight }
            }
        }
        
        // Base shadow
        layer.enabled: true
        layer.effect: DropShadow {
            id: cardShadow
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: hovered ? ScaleManager.scaleSize(4) : ScaleManager.scaleSize(2)
            radius: hovered ? 16 : 8
            samples: hovered ? 24 : 16
            color: hovered ? Colors.shadowDark : Colors.shadow
            
            Behavior on verticalOffset { NumberAnimation { duration: Animations.normal; easing.type: Animations.easeOutCubic } }
            Behavior on radius { NumberAnimation { duration: Animations.normal; easing.type: Animations.easeOutCubic } }
            Behavior on color { ColorAnimation { duration: Animations.normal } }
        }
        
        // Glow border on hover
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.color: Colors.primary
            border.width: 1
            opacity: hovered && hoverable ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: Animations.normal } }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: root.clicked()
            enabled: root.hoverable
        }
        
        HoverHandler {
            id: hoverHandler
            enabled: root.hoverable
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }
    
    Item {
        id: container
        anchors.fill: parent
        anchors.margins: ScaleManager.scaleSpacing(Spacing.paddingCard)
        
        property real implicitWidth: childrenRect.width
        property real implicitHeight: childrenRect.height
    }
    
    // Animations
    states: State {
        name: "hovered"
        when: hoverable && hoverHandler.hovered
        PropertyChanges { target: bg; color: Qt.lighter(Colors.surfaceElevated, 1.05) }
        PropertyChanges { target: hoverTransform; y: -4 }
    }
    
    transitions: Transition {
        ColorAnimation { duration: Animations.normal }
        NumberAnimation {
            property: "y"
            duration: Animations.normal
            easing.type: Animations.easeOutCubic
        }
    }
}
