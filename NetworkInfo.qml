import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

Item {
  id: root

  property color foreground: Color.bar.text
  property color separator: Qt.alpha(foreground, 0.35)

  readonly property string home: Quickshell.env("HOME")
  readonly property string collector: home + "/.config/omarchy/plugins/omarchy-infobar/scripts/network.sh"

  property string ssid: ""
  property string signal: "--"
  property string address: "--"

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  function refresh() {
    if (!collectorProcess.running) collectorProcess.running = true
  }

  function consume(raw) {
    var fields = String(raw || "").trim().split("|")
    if (fields.length < 3) return
    ssid = fields[0] || ""
    signal = fields[1] || "--"
    address = fields[2] || "--"
  }

  function networkText() {
    if (!root.ssid) return "Wi-Fi Offline"
    return "Wi-Fi " + root.ssid + " · " + root.signal + "% · " + root.address
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: collectorProcess
    command: ["bash", root.collector]
    stdout: StdioCollector {
      onStreamFinished: root.consume(text)
    }
  }

  Text {
    id: content
    text: root.networkText()
    color: root.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    verticalAlignment: Text.AlignVCenter
  }
}
