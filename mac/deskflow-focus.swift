import CoreGraphics
import Foundation

func postKey(_ keyCode: CGKeyCode, down: Bool, flags: CGEventFlags) {
    guard let source = CGEventSource(stateID: .hidSystemState),
          let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else {
        return
    }
    event.flags = flags
    event.post(tap: .cghidEventTap)
}

func tapKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
    postKey(keyCode, down: true, flags: flags)
    usleep(80_000)
    postKey(keyCode, down: false, flags: flags)
    usleep(180_000)
}

guard CommandLine.arguments.count == 2 else {
    fputs("usage: deskflow-focus windows|mac\n", stderr)
    exit(2)
}

let deskflowFlags: CGEventFlags = [.maskControl, .maskCommand]

switch CommandLine.arguments[1] {
case "windows":
    // Deskflow config binds Control+Command+Right to switch right and lock cursor.
    tapKey(124, flags: deskflowFlags)
case "mac":
    // Deskflow config binds Control+Command+Left to switch left and unlock cursor.
    tapKey(123, flags: deskflowFlags)
default:
    fputs("unknown mode\n", stderr)
    exit(2)
}
