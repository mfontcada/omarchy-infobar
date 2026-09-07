import QtQuick
import Quickshell.Services.UPower
import qs.Commons

Item {
  id: root

  property color foreground: Color.bar.text

  readonly property var batteryDevice: UPower.displayDevice

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

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

  Text {
    id: content
    text: root.batteryText()
    color: root.foreground
    font.family: Style.font.family
    font.pixelSize: Style.font.body
    verticalAlignment: Text.AlignVCenter
  }
}
