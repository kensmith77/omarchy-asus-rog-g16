import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "asus.rog-g16"
  ipcTarget: "asus.rog-g16"

  property var snapshot: ({})
  property int page: 0
  property string statusText: "Loading laptop state…"
  property bool busy: false
  property var commandQueue: []

  readonly property string controlPath: decodeURIComponent(
    Qt.resolvedUrl("bin/asus-g16-control").toString().replace(/^file:\/\//, ""))
  readonly property var config: snapshot.config || ({})
  readonly property var touchpad: config.touchpad || ({})
  readonly property var gestures: config.gestures || ({})
  readonly property var keys: config.keys || ({})
  readonly property var power: snapshot.power || ({ profiles: ["Quiet", "Balanced", "Performance"] })
  readonly property var armoury: snapshot.armoury || ({})

  readonly property var actionOptions: [
    { value: "disabled", label: "Disabled" },
    { value: "volume-down", label: "Volume down" },
    { value: "volume-up", label: "Volume up" },
    { value: "volume-mute", label: "Mute speakers" },
    { value: "mic-mute", label: "Mute microphone" },
    { value: "keyboard-light-cycle", label: "Cycle keyboard light" },
    { value: "control-panel", label: "Open this panel" },
    { value: "launcher", label: "App launcher" },
    { value: "terminal", label: "Terminal" },
    { value: "browser", label: "Browser" },
    { value: "screenshot", label: "Screenshot" },
    { value: "play-pause", label: "Play / pause" },
    { value: "codex", label: "Codex" }
  ]

  readonly property var gestureOptions: [
    { value: "none", label: "Disabled" },
    { value: "workspace", label: "Workspace swipe" },
    { value: "launcher", label: "App launcher" },
    { value: "special-workspace", label: "Special workspace" },
    { value: "previous-workspace", label: "Previous workspace" },
    { value: "next-workspace", label: "Next workspace" },
    { value: "focus-left", label: "Focus left" },
    { value: "focus-right", label: "Focus right" },
    { value: "fullscreen", label: "Toggle fullscreen" },
    { value: "close-window", label: "Close window" },
    { value: "play-pause", label: "Play / pause" },
    { value: "screenshot", label: "Screenshot" }
  ]

  function runCommand(args, message) {
    commandQueue = commandQueue.concat([{ args: args, message: message || "Applying…" }])
    pumpQueue()
  }

  function pumpQueue() {
    if (actionProc.running || commandQueue.length === 0) return
    var next = commandQueue[0]
    commandQueue = commandQueue.slice(1)
    statusText = next.message
    busy = true
    actionProc.command = [controlPath].concat(next.args)
    actionProc.running = true
  }

  function refresh() {
    if (!stateProc.running) stateProc.running = true
  }

  function setConfig(path, value) {
    runCommand(["set", path, String(value)], "Saving " + path + "…")
  }

  function setToggle(path, current) {
    setConfig(path, !current)
  }

  Component.onCompleted: runCommand(["install-config"], "Preparing G16 controls…")
  onOpenedChanged: if (opened) refresh()

  Process {
    id: stateProc
    command: [root.controlPath, "state"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.snapshot = JSON.parse(String(text || "{}"))
          root.statusText = "Ready"
        } catch (e) {
          root.statusText = "Could not read laptop state"
          console.warn("asus.rog-g16", e)
        }
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (String(text || "").trim() !== "") console.warn("asus.rog-g16", String(text).trim())
    }
  }

  Process {
    id: actionProc
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var error = String(text || "").trim()
        if (error !== "") root.statusText = error.split("\n").pop()
      }
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode === 0) root.statusText = "Applied"
      root.refresh()
      root.pumpQueue()
    }
  }

  Timer {
    interval: 15000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌"
    active: root.opened
    tooltipText: "ROG G16 controls"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.refresh()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(570))
    contentHeight: panel.fittedContentHeight(Math.min(contentColumn.implicitHeight, Style.space(720)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroGlyph.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroGlyph
            text: "󰌌"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroGlyph.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              width: parent.width
              text: "ROG Zephyrus G16"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: ((root.snapshot.device || {}).board || "GU605") + "  ·  " + root.statusText
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
        }

        Row {
          id: tabs
          width: parent.width
          spacing: Style.space(6)
          property real tabWidth: (width - spacing * 3) / 4

          Repeater {
            model: ["SYSTEM", "LIGHTING", "TOUCHPAD", "KEYS"]
            Button {
              required property string modelData
              required property int index
              width: tabs.tabWidth
              text: modelData
              fontSize: Style.font.caption
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              selected: root.page === index
              onClicked: root.page = index
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Flickable {
          width: parent.width
          height: Math.min(pageContainer.implicitHeight, Style.space(600))
          contentWidth: width
          contentHeight: pageContainer.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: pageContainer
            width: parent.width - Style.space(12)
            spacing: Style.space(12)

            Column {
              visible: root.page === 0
              width: parent.width
              spacing: Style.space(12)

              PanelSectionHeader { text: "POWER"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

              Dropdown {
                width: parent.width
                label: "Performance profile"
                value: root.power.profile || "Balanced"
                options: root.power.profiles || ["Quiet", "Balanced", "Performance"]
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onChanged: function(value) { root.runCommand(["set-profile", value], "Changing performance profile…") }
              }

              Column {
                width: parent.width
                spacing: Style.spacing.labelGap
                Row {
                  width: parent.width
                  Text { text: "Battery charge limit"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
                  Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2); height: 1 }
                  Text { text: Math.round(chargeSlider.dragging ? chargeSlider.liveValue : chargeSlider.value) + "%"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
                }
                PanelSlider {
                  id: chargeSlider
                  width: parent.width
                  bar: root.bar
                  minimum: 20
                  maximum: 100
                  step: 5
                  integer: true
                  tickCount: 9
                  value: Number(root.power.chargeLimit || 100)
                  onReleased: function(value) { root.runCommand(["set-charge-limit", String(Math.round(value))], "Setting charge limit…") }
                }
              }

              PanelSeparator { foreground: root.bar.foreground }
              PanelSectionHeader { text: "FIRMWARE"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }

              Toggle {
                visible: (root.armoury.bootSound || {}).supported === true
                width: parent.width
                label: "Boot sound"
                description: "Play the ROG sound during startup"
                checked: (root.armoury.bootSound || {}).value === true
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.runCommand(["set-armoury", "boot_sound", checked ? "0" : "1"], "Updating boot sound…")
              }
              Toggle {
                visible: (root.armoury.panelOverdrive || {}).supported === true
                width: parent.width
                label: "Panel overdrive"
                description: "Faster display response; uses more power"
                checked: (root.armoury.panelOverdrive || {}).value === true
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.runCommand(["set-armoury", "panel_overdrive", checked ? "0" : "1"], "Updating panel overdrive…")
              }
              Toggle {
                visible: (root.armoury.dgpuDisable || {}).supported === true
                width: parent.width
                label: "Eco GPU mode"
                description: "Disable the NVIDIA GPU to improve battery life"
                checked: (root.armoury.dgpuDisable || {}).value === true
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.runCommand(["set-armoury", "dgpu_disable", checked ? "0" : "1"], "Changing GPU mode…")
              }
              Toggle {
                visible: (root.armoury.gpuMuxMode || {}).supported === true
                width: parent.width
                label: "Discrete GPU MUX"
                description: "Route the display directly through NVIDIA; logout may be required"
                checked: (root.armoury.gpuMuxMode || {}).value === true
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.runCommand(["set-armoury", "gpu_mux_mode", checked ? "0" : "1"], "Changing MUX mode…")
              }

              PanelSeparator { foreground: root.bar.foreground }
              PanelSectionHeader { text: "ADVANCED POWER TUNING"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
              Text {
                width: parent.width
                text: "Firmware-enforced limits for the current performance profile. Higher values increase heat, fan noise, and battery drain."
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              FirmwareSlider {
                visible: (root.armoury.dynamicBoost || {}).supported === true
                title: "NVIDIA Dynamic Boost"; attribute: "nv_dynamic_boost"
                currentValue: (root.armoury.dynamicBoost || {}).value || 20
                minimumValue: 5; maximumValue: 20; suffix: " W"
              }
              FirmwareSlider {
                visible: (root.armoury.tgp || {}).supported === true
                title: "NVIDIA TGP"; attribute: "nv_tgp"
                currentValue: (root.armoury.tgp || {}).value || 90
                minimumValue: 80; maximumValue: 110; suffix: " W"
              }
              FirmwareSlider {
                visible: (root.armoury.tempTarget || {}).supported === true
                title: "NVIDIA temperature target"; attribute: "nv_temp_target"
                currentValue: (root.armoury.tempTarget || {}).value || 87
                minimumValue: 75; maximumValue: 87; suffix: " °C"
              }
              FirmwareSlider {
                visible: (root.armoury.pl1 || {}).supported === true
                title: "CPU sustained power (PL1/SPL)"; attribute: "ppt_pl1_spl"
                currentValue: (root.armoury.pl1 || {}).value || 45
                minimumValue: 45; maximumValue: 85; suffix: " W"
              }
              FirmwareSlider {
                visible: (root.armoury.pl2 || {}).supported === true
                title: "CPU short boost (PL2/SPPT)"; attribute: "ppt_pl2_sppt"
                currentValue: (root.armoury.pl2 || {}).value || 56
                minimumValue: 56; maximumValue: 110; suffix: " W"
              }
            }

            Column {
              visible: root.page === 1
              width: parent.width
              spacing: Style.space(12)

              PanelSectionHeader { text: "KEYBOARD LIGHTING"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
              Dropdown {
                width: parent.width
                label: "Brightness"
                value: (root.snapshot.lighting || {}).brightness || "med"
                options: [
                  { value: "off", label: "Off" }, { value: "low", label: "Low" },
                  { value: "med", label: "Medium" }, { value: "high", label: "High" }
                ]
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onChanged: function(value) { root.runCommand(["set-led-brightness", value], "Setting keyboard brightness…") }
              }
              Dropdown {
                id: effectDropdown
                width: parent.width
                label: "Aura effect"
                value: "static"
                options: [
                  { value: "static", label: "Static" },
                  { value: "breathe", label: "Breathe" },
                  { value: "rainbow-wave", label: "Rainbow wave" }
                ]
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
              }
              Row {
                width: parent.width
                spacing: Style.space(8)
                TextField {
                  id: primaryColour
                  width: (parent.width - parent.spacing) / 2
                  placeholderText: "Primary RGB (7c3aed)"
                  text: "7c3aed"
                  foreground: root.bar.foreground
                }
                TextField {
                  id: secondaryColour
                  width: (parent.width - parent.spacing) / 2
                  placeholderText: "Secondary RGB (00d4ff)"
                  text: "00d4ff"
                  foreground: root.bar.foreground
                }
              }
              Row {
                width: parent.width
                spacing: Style.space(8)
                Dropdown {
                  id: effectSpeed
                  width: (parent.width - parent.spacing) / 2
                  label: "Speed"
                  value: "med"
                  options: [{value:"low",label:"Low"},{value:"med",label:"Medium"},{value:"high",label:"High"}]
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                }
                Dropdown {
                  id: effectDirection
                  width: (parent.width - parent.spacing) / 2
                  label: "Direction"
                  value: "right"
                  options: ["left", "right", "up", "down"]
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                }
              }
              Button {
                width: parent.width
                text: "Apply Aura effect"
                bordered: true
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.runCommand([
                  "set-led-effect", effectDropdown.value, primaryColour.text,
                  secondaryColour.text, effectSpeed.value, effectDirection.value
                ], "Applying Aura effect…")
              }
            }

            Column {
              visible: root.page === 2
              width: parent.width
              spacing: Style.space(12)

              PanelSectionHeader { text: "TRACKPAD"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
              Toggle {
                width: parent.width; label: "Trackpad"; description: "Enable the built-in ASUP1207 touchpad"
                checked: root.touchpad.enabled !== false; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.enabled", checked)
              }
              Toggle {
                width: parent.width; label: "Natural scrolling"; description: "Content follows your fingers"
                checked: root.touchpad.naturalScroll === true; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.naturalScroll", checked)
              }
              Toggle {
                width: parent.width; label: "Tap to click"; description: "One-finger tap clicks; two and three fingers follow the tap map below"
                checked: root.touchpad.tapToClick !== false; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.tapToClick", checked)
              }
              Dropdown {
                width: parent.width
                label: "Two / three-finger taps"
                value: root.touchpad.tapMap || "lrm"
                options: [
                  { value: "lrm", label: "2 = right click, 3 = middle click" },
                  { value: "lmr", label: "2 = middle click, 3 = right click" }
                ]
                foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onChanged: function(value) { root.setConfig("touchpad.tapMap", value) }
              }
              Toggle {
                width: parent.width; label: "Clickfinger behavior"; description: "Physical 2/3-finger clicks become right/middle click"
                checked: root.touchpad.clickfinger !== false; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.clickfinger", checked)
              }
              Toggle {
                width: parent.width; label: "Disable while typing"; description: "Prevents accidental palm movement"
                checked: root.touchpad.disableWhileTyping !== false; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.disableWhileTyping", checked)
              }
              Toggle {
                width: parent.width; label: "Drag lock"; description: "Continue dragging after lifting a finger"
                checked: root.touchpad.dragLock === true; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.dragLock", checked)
              }
              Toggle {
                width: parent.width; label: "Middle-button emulation"; description: "Press left and right together for middle click"
                checked: root.touchpad.middleButtonEmulation === true; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily
                onClicked: root.setToggle("touchpad.middleButtonEmulation", checked)
              }

              Column {
                width: parent.width; spacing: Style.spacing.labelGap
                Row {
                  width: parent.width
                  Text { text: "Scroll speed"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
                  Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth); height: 1 }
                  Text { text: Number(scrollSlider.dragging ? scrollSlider.liveValue : scrollSlider.value).toFixed(1) + "×"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
                }
                PanelSlider {
                  id: scrollSlider; width: parent.width; bar: root.bar; minimum: 0.1; maximum: 2.0; step: 0.1
                  value: Number(root.touchpad.scrollFactor || 0.4)
                  onReleased: function(value) { root.setConfig("touchpad.scrollFactor", Number(value).toFixed(1)) }
                }
              }
              Column {
                width: parent.width; spacing: Style.spacing.labelGap
                Row {
                  width: parent.width
                  Text { text: "Pointer speed"; color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body }
                  Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth); height: 1 }
                  Text { text: Number(pointerSlider.dragging ? pointerSlider.liveValue : pointerSlider.value).toFixed(1); color: root.bar.foreground; font.family: root.bar.fontFamily; font.pixelSize: Style.font.body; font.bold: true }
                }
                PanelSlider {
                  id: pointerSlider; width: parent.width; bar: root.bar; minimum: -1.0; maximum: 1.0; step: 0.1
                  value: Number(root.touchpad.sensitivity || 0)
                  onReleased: function(value) { root.setConfig("touchpad.sensitivity", Number(value).toFixed(1)) }
                }
              }

              PanelSeparator { foreground: root.bar.foreground }
              PanelSectionHeader { text: "SWIPE GESTURES"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
              Text {
                width: parent.width
                text: "Four-finger taps are not emitted by libinput on this hardware, so the fourth-finger actions use swipes. Two-finger movement remains scrolling."
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              GestureRow { title: "3 fingers · left / right"; configKey: "threeHorizontal"; currentValue: root.gestures.threeHorizontal || "workspace" }
              GestureRow { title: "3 fingers · up"; configKey: "threeUp"; currentValue: root.gestures.threeUp || "launcher" }
              GestureRow { title: "3 fingers · down"; configKey: "threeDown"; currentValue: root.gestures.threeDown || "special-workspace" }
              GestureRow { title: "4 fingers · left"; configKey: "fourLeft"; currentValue: root.gestures.fourLeft || "previous-workspace" }
              GestureRow { title: "4 fingers · right"; configKey: "fourRight"; currentValue: root.gestures.fourRight || "next-workspace" }
              GestureRow { title: "4 fingers · up"; configKey: "fourUp"; currentValue: root.gestures.fourUp || "fullscreen" }
              GestureRow { title: "4 fingers · down"; configKey: "fourDown"; currentValue: root.gestures.fourDown || "none" }
            }

            Column {
              visible: root.page === 3
              width: parent.width
              spacing: Style.space(12)

              PanelSectionHeader { text: "SPECIAL KEYS"; foreground: root.bar.foreground; fontFamily: root.bar.fontFamily }
              Text {
                width: parent.width
                text: "M1–M3 arrive as standard media keys. M4 uses XF86Launch1; Copilot uses Super+Shift+F23 on this keyboard generation."
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily; font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              KeyRow { title: "M1"; configKey: "m1"; currentValue: root.keys.m1 || "volume-down" }
              KeyRow { title: "M2"; configKey: "m2"; currentValue: root.keys.m2 || "volume-up" }
              KeyRow { title: "M3"; configKey: "m3"; currentValue: root.keys.m3 || "mic-mute" }
              KeyRow { title: "M4"; configKey: "m4"; currentValue: root.keys.m4 || "control-panel" }
              KeyRow { title: "Copilot"; configKey: "copilot"; currentValue: root.keys.copilot || "codex" }
            }
          }
        }
      }
    }
  }

  component GestureRow: Row {
    required property string title
    required property string configKey
    required property string currentValue
    width: parent.width
    spacing: Style.space(10)
    Text {
      width: parent.width * 0.38
      text: parent.title
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
    }
    Dropdown {
      width: parent.width * 0.62 - parent.spacing
      showLabel: false
      value: parent.currentValue
      options: root.gestureOptions
      foreground: root.bar.foreground
      fontFamily: root.bar.fontFamily
      onChanged: function(value) { root.setConfig("gestures." + parent.configKey, value) }
    }
  }

  component KeyRow: Row {
    required property string title
    required property string configKey
    required property string currentValue
    width: parent.width
    spacing: Style.space(10)
    Text {
      width: parent.width * 0.25
      text: parent.title
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
      anchors.verticalCenter: parent.verticalCenter
    }
    Dropdown {
      width: parent.width * 0.75 - parent.spacing
      showLabel: false
      value: parent.currentValue
      options: root.actionOptions
      foreground: root.bar.foreground
      fontFamily: root.bar.fontFamily
      onChanged: function(value) { root.setConfig("keys." + parent.configKey, value) }
    }
  }

  component FirmwareSlider: Column {
    required property string title
    required property string attribute
    required property real currentValue
    required property real minimumValue
    required property real maximumValue
    property string suffix: ""
    width: parent.width
    spacing: Style.spacing.labelGap

    Row {
      width: parent.width
      Text {
        text: parent.parent.title
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
      Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth); height: 1 }
      Text {
        text: Math.round(firmwareControl.dragging ? firmwareControl.liveValue : firmwareControl.value) + parent.parent.suffix
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }
    PanelSlider {
      id: firmwareControl
      width: parent.width
      bar: root.bar
      minimum: parent.minimumValue
      maximum: parent.maximumValue
      step: 1
      integer: true
      value: parent.currentValue
      onReleased: function(value) {
        root.runCommand(["set-armoury", parent.attribute, String(Math.round(value))], "Updating " + parent.title + "…")
      }
    }
  }
}
