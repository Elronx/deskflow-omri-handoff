import CoreGraphics
import Darwin
import Foundation

let deskflowPort = 24800
let navigationCooldownSeconds: TimeInterval = 0.70

func navigationCooldownStatePath() -> String {
    let cacheRoot = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    return cacheRoot
        .appendingPathComponent("com.local.deskflow-focus", isDirectory: true)
        .appendingPathComponent("navigation-cooldown.state")
        .path
}

func navigationCooldownAllowsEvent(
    statePath: String,
    now: TimeInterval = ProcessInfo.processInfo.systemUptime,
    interval: TimeInterval = navigationCooldownSeconds
) -> Bool {
    let stateURL = URL(fileURLWithPath: statePath)
    do {
        try FileManager.default.createDirectory(
            at: stateURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    } catch {
        return false
    }

    let descriptor = Darwin.open(statePath, O_CREAT | O_RDWR, mode_t(S_IRUSR | S_IWUSR))
    guard descriptor >= 0 else { return false }
    defer { Darwin.close(descriptor) }
    guard flock(descriptor, LOCK_EX) == 0 else { return false }

    var buffer = [UInt8](repeating: 0, count: 64)
    let bytesRead = buffer.withUnsafeMutableBytes { rawBuffer in
        Darwin.read(descriptor, rawBuffer.baseAddress, 63)
    }
    if bytesRead > 0 {
        let text = String(decoding: buffer.prefix(Int(bytesRead)), as: UTF8.self)
        if let previous = TimeInterval(text.trimmingCharacters(in: .whitespacesAndNewlines)),
           now >= previous,
           now - previous < interval {
            return false
        }
    }

    let bytes = Array(String(format: "%.6f\n", now).utf8)
    guard ftruncate(descriptor, 0) == 0,
          lseek(descriptor, 0, SEEK_SET) == 0 else { return false }
    let written = bytes.withUnsafeBytes { rawBuffer in
        Darwin.write(descriptor, rawBuffer.baseAddress, bytes.count)
    }
    guard written == bytes.count else { return false }
    _ = Darwin.fsync(descriptor)
    return true
}

func postKey(_ keyCode: CGKeyCode, down: Bool, flags: CGEventFlags) {
    guard let source = CGEventSource(stateID: .hidSystemState),
          let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down)
    else { return }
    event.flags = flags
    event.post(tap: .cghidEventTap)
}

func tapKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
    postKey(keyCode, down: true, flags: flags)
    usleep(20_000)
    postKey(keyCode, down: false, flags: flags)
    usleep(20_000)
}

func tapKeyChord(
    _ keyCode: CGKeyCode,
    modifiers: [(keyCode: CGKeyCode, flag: CGEventFlags)]
) {
    var activeFlags: CGEventFlags = []
    for modifier in modifiers {
        activeFlags.insert(modifier.flag)
        postKey(modifier.keyCode, down: true, flags: activeFlags)
        usleep(20_000)
    }
    postKey(keyCode, down: true, flags: activeFlags)
    usleep(20_000)
    postKey(keyCode, down: false, flags: activeFlags)
    usleep(20_000)
    for modifier in modifiers.reversed() {
        activeFlags.remove(modifier.flag)
        postKey(modifier.keyCode, down: false, flags: activeFlags)
        usleep(20_000)
    }
}

func clickOtherMouseButton(_ rawButton: UInt32) {
    guard let source = CGEventSource(stateID: .hidSystemState),
          let probe = CGEvent(source: source),
          let button = CGMouseButton(rawValue: rawButton),
          let down = CGEvent(
              mouseEventSource: source,
              mouseType: .otherMouseDown,
              mouseCursorPosition: probe.location,
              mouseButton: button
          ),
          let up = CGEvent(
              mouseEventSource: source,
              mouseType: .otherMouseUp,
              mouseCursorPosition: probe.location,
              mouseButton: button
          )
    else { return }

    down.setIntegerValueField(.mouseEventButtonNumber, value: Int64(rawButton))
    up.setIntegerValueField(.mouseEventButtonNumber, value: Int64(rawButton))
    down.post(tap: .cghidEventTap)
    usleep(20_000)
    up.post(tap: .cghidEventTap)
}

func deskflowHasConnectedClient() -> Bool {
    let process = Process()
    let stdout = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
    process.arguments = [
        "-nP", "-a", "-c", "deskflow-core", "-iTCP:\(deskflowPort)", "-sTCP:ESTABLISHED",
    ]
    process.standardOutput = stdout
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return false
    }
    guard process.terminationStatus == 0 else { return false }
    let data = stdout.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else { return false }
    return output.contains("->") && output.contains(":\(deskflowPort)")
}

guard CommandLine.arguments.count == 2 else {
    fputs(
        "usage: deskflow-focus windows|mac|tab-previous|tab-next|middle|back|forward|status\n",
        stderr
    )
    exit(2)
}

let privateFocusFlags: CGEventFlags = [.maskControl, .maskCommand]
let leftControl: (keyCode: CGKeyCode, flag: CGEventFlags) = (59, .maskControl)
let leftShift: (keyCode: CGKeyCode, flag: CGEventFlags) = (56, .maskShift)

switch CommandLine.arguments[1] {
case "windows":
    // Never move the pointer or inject a screen-selection shortcut unless a
    // real Deskflow client is connected.
    guard deskflowHasConnectedClient() else { exit(0) }
    tapKey(124, flags: privateFocusFlags)
case "mac":
    tapKey(123, flags: privateFocusFlags)
case "tab-previous":
    tapKeyChord(48, modifiers: [leftControl, leftShift])
case "tab-next":
    tapKeyChord(48, modifiers: [leftControl])
case "middle":
    clickOtherMouseButton(2)
case "back":
    guard navigationCooldownAllowsEvent(statePath: navigationCooldownStatePath()) else { exit(0) }
    clickOtherMouseButton(3)
case "forward":
    guard navigationCooldownAllowsEvent(statePath: navigationCooldownStatePath()) else { exit(0) }
    clickOtherMouseButton(4)
case "status":
    print("connected=\(deskflowHasConnectedClient())")
default:
    fputs("unknown mode\n", stderr)
    exit(2)
}
