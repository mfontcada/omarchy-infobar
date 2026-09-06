import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons

Item {
  id: root

  property color foreground: Color.bar.text
  property color separator: Qt.alpha(foreground, 0.35)
  property color accent: Color.accent

  readonly property string home: Quickshell.env("HOME")
  readonly property string collector: home + "/.config/omarchy/plugins/omarchy-infobar/scripts/sysinfo.sh"
  readonly property var batteryDevice: UPower.displayDevice

  property string cpuUsage: "--"
  property string cpuTemperature: "--"
  property string gpuUsage: "--"
  property string gpuTemperature: "--"
  property string ram: "--"
  property string disk: "--"

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  function refresh() {
    if (!collectorProcess.running) collectorProcess.running = true
  }

  function consume(raw) {
    var fields = String(raw || "").trim().split("|")
    if (fields.length < 6) return
    cpuUsage = fields[0] || "--"
    cpuTemperature = fields[1] || "--"
    gpuUsage = fields[2] || "--"
    gpuTemperature = fields[3] || "--"
    ram = fields[4] || "--"
    disk = fields[5] || "--"
  }

  function formatBatteryTime(seconds) {
    var value = Number(seconds)
    if (!isFinite(value) || value <= 0) return "--"

    var minutes = Math.round(value / 60)
    if (minutes < 60) return minutes + "m"

    var hours = Math.floor(minutes / 60)
    var remainingMinutes = minutes % 60
    return remainingMinutes > 0
      ? hours + "h " + remainingMinutes + "m"
      : hours + "h"
  }

  function batteryText() {
    var device = root.batteryDevice
    if (!device || !device.isPresent) return "Battery --"

    var percentage = Math.round(Number(device.percentage || 0) * 100)
    if (device.state === UPowerDeviceState.FullyCharged) {
      return "Battery " + percentage + "% · Full"
    }

    if (device.state === UPowerDeviceState.Charging) {
      return "Battery " + percentage + "% · " + formatBatteryTime(device.timeToFull) + " to full"
    }

    if (device.state === UPowerDeviceState.Discharging) {
      return "Battery " + percentage + "% · " + formatBatteryTime(device.timeToEmpty) + " left"
    }

    return "Battery " + percentage + "% · --"
  }

  Component.onCompleted: refresh()

  Timer {
    interval: 2000
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

  Row {
    id: content
    spacing: Style.spacing.sm

    Text {
      text: "CPU " + root.cpuUsage + "% " + root.cpuTemperature + "°C"
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      text: "|"
      color: root.separator
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      text: "GPU " + root.gpuUsage + "% " + root.gpuTemperature + "°C"
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      text: "|"
      color: root.separator
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      text: "RAM " + root.ram
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      text: "|"
      color: root.separator
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      text: "Disk " + root.disk
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      text: "|"
      color: root.separator
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }

    Text {
      text: root.batteryText()
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      verticalAlignment: Text.AlignVCenter
    }
  }
}
