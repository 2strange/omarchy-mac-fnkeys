import QtQuick
import Quickshell
import Quickshell.Io

// Headless owner of the function-row state. The bar widget (one per monitor)
// reads from here so every bar shows the same mode and one toggle at a time
// runs.
Item {
  id: root

  // Injected by omarchy-shell.
  property var shell: null

  readonly property string pluginId: "io.github.alnandr.macbook-fn-keys"
  readonly property string helper: "/usr/local/libexec/omarchy-mac-fnmode"
  readonly property string parameterPath: "/sys/module/hid_apple/parameters/fnmode"
  readonly property string setupScript: localPath(Qt.resolvedUrl("scripts/setup"))

  // "media"  fnmode=1: printed keys (brightness, volume, media) without Fn
  // "fkeys"  fnmode=2: F1-F12 without Fn
  // "other"  fnmode=0 or 3
  // "unavailable"  hid_apple is not loaded on this machine
  property string mode: "unavailable"
  property bool available: false
  // The root helper is installed. The sudoers rule cannot be read as a user,
  // so a refused toggle sets sudoDenied instead.
  property bool setupDone: false
  property bool sudoDenied: false
  property bool busy: false
  property string lastError: ""

  readonly property bool ready: available && setupDone && !sudoDenied

  function localPath(url) {
    return decodeURIComponent(String(url).replace(/^file:\/\//, ""))
  }

  function refresh() {
    parameterFile.reload()
    helperFile.reload()
  }

  function applyParameter(text) {
    var value = String(text).trim()
    available = true
    if (value === "1") mode = "media"
    else if (value === "2") mode = "fkeys"
    else mode = "other"
  }

  function setMode(target) {
    if (busy || !available) return
    busy = true
    lastError = ""
    setProcess.command = ["sudo", "-n", helper, String(target)]
    setProcess.running = true
  }

  function toggle() {
    setMode(mode === "media" ? 2 : 1)
  }

  // Setup needs the user's password once, so it runs in Omarchy's floating
  // terminal rather than silently from the shell process.
  function runSetup() {
    Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", setupScript])
  }

  Component.onCompleted: refresh()

  // sysfs does not deliver inotify events, so the kernel value is polled. It
  // only changes through the helper or a manual write, so a slow poll is
  // enough; toggles update the mode immediately from the helper's reply.
  Timer {
    interval: 10000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  FileView {
    id: parameterFile
    path: root.parameterPath
    printErrors: false
    onLoaded: root.applyParameter(text())
    onFileChanged: root.applyParameter(text())
    onLoadFailed: {
      root.available = false
      root.mode = "unavailable"
    }
  }

  FileView {
    id: helperFile
    path: root.helper
    printErrors: false
    onLoaded: root.setupDone = true
    onLoadFailed: root.setupDone = false
  }

  // In media mode F6 sends KEY_SLEEP, and logind's default HandleSuspendKey
  // would suspend the machine before Hyprland's Do Not Disturb binding ran.
  // Hold a suspend-key inhibitor only while that mode is active. The child
  // exits on stdin EOF, so the inhibitor is released even if the shell dies.
  Process {
    id: suspendKeyInhibitor
    running: root.available && root.mode === "media"
    stdinEnabled: true
    command: [
      "systemd-inhibit",
      "--what=handle-suspend-key",
      "--who=MacBook Function Keys",
      "--why=F6 is Do Not Disturb while the function row sends media keys",
      "--mode=block",
      "sh", "-c", "cat >/dev/null"
    ]
  }

  Process {
    id: setProcess
    stdout: StdioCollector {
      id: setStdout
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: setStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode === 0) {
        root.sudoDenied = false
        var label = String(setStdout.text).trim()
        if (label === "media" || label === "fkeys") root.mode = label
      } else {
        var error = String(setStderr.text).trim()
        // sudo -n reports a missing rule as "a password is required".
        root.sudoDenied = error.indexOf("password") !== -1 || error.indexOf("sudo:") === 0
        root.lastError = error || "helper exited with status " + exitCode
      }
      root.refresh()
    }
  }
}
