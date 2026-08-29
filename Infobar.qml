import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  readonly property int barHeight: Style.bar.sizeHorizontal
  readonly property color foreground: Color.bar.text
  readonly property color background: Color.bar.background
  readonly property color accent: Color.accent
  readonly property color separator: Qt.alpha(foreground, 0.35)

  // The panel is a persistent layer-shell surface, separate from the stock
  // Omarchy bar. Variants gives each connected output its own bar instance.
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: window
        required property var modelData

        screen: modelData
        visible: true
        color: "transparent"
        anchors {
          left: true
          right: true
          bottom: true
        }
        implicitHeight: root.barHeight
        exclusionMode: ExclusionMode.Auto
        WlrLayershell.namespace: "omarchy-infobar"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
          anchors.fill: parent
          color: root.background

          Row {
            anchors {
              fill: parent
              leftMargin: Style.space(12)
              rightMargin: Style.space(12)
            }
            spacing: Style.spacing.md

            SystemInfo {
              anchors.verticalCenter: parent.verticalCenter
              foreground: root.foreground
              separator: root.separator
              accent: root.accent
            }
          }
        }
      }
    }
  }
}
