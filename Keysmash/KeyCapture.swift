//
//  KeyCapture.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI
import AppKit

struct KeyEventInfo {
    enum Phase {
        case down
        case up
    }

    let phase: Phase
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    let isRepeat: Bool

    var physicalKeyName: String {
        qwertyKeyMap[keyCode] ?? "Unknown (\(keyCode))"
    }
}

struct KeyCaptureView: NSViewRepresentable {
    let onKeyEvent: (KeyEventInfo) -> Void

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyEvent = onKeyEvent
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onKeyEvent = onKeyEvent
    }
}

final class KeyCaptureNSView: NSView {
    var onKeyEvent: ((KeyEventInfo) -> Void)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        // Request keyboard focus when attached to a window.
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else {
                return
            }

            window.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        onKeyEvent?(
            KeyEventInfo(
                phase: .down,
                keyCode: event.keyCode,
                modifiers: event.modifierFlags,
                isRepeat: event.isARepeat
            )
        )
    }

    override func keyUp(with event: NSEvent) {
        onKeyEvent?(
            KeyEventInfo(
                phase: .up,
                keyCode: event.keyCode,
                modifiers: event.modifierFlags,
                isRepeat: false
            )
        )
    }
}

let qwertyKeyMap: [UInt16: String] = [
    // Number row
    18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
    22: "6", 26: "7", 28: "8", 25: "9", 29: "0",

    // Top letter row
    12: "Q", 13: "W", 14: "E", 15: "R", 17: "T",
    16: "Y", 32: "U", 34: "I", 31: "O", 35: "P",

    // Home row
    0: "A", 1: "S", 2: "D", 3: "F", 5: "G",
    4: "H", 38: "J", 40: "K", 37: "L",

    // Bottom letter row
    6: "Z", 7: "X", 8: "C", 9: "V", 11: "B",
    45: "N", 46: "M",

    // Punctuation
    24: "=", 27: "-", 33: "[", 30: "]",
    41: ";", 39: "'", 42: "\\", 43: ",",
    47: ".", 44: "/",
    50: "`",

    // Whitespace and control keys
    49: "Space",
    36: "Return",
    48: "Tab",
    51: "Delete",
    53: "Escape",
    117: "Forward Delete",

    // Navigation
    115: "Home",
    119: "End",
    116: "Page Up",
    121: "Page Down",
    123: "Left",
    124: "Right",
    125: "Down",
    126: "Up",

    // Function keys
    122: "F1", 120: "F2", 99: "F3", 118: "F4",
    96: "F5", 97: "F6", 98: "F7", 100: "F8",
    101: "F9", 109: "F10", 103: "F11", 111: "F12",

    // Keypad
    82: "Keypad 0", 83: "Keypad 1", 84: "Keypad 2",
    85: "Keypad 3", 86: "Keypad 4", 87: "Keypad 5",
    88: "Keypad 6", 89: "Keypad 7", 91: "Keypad 8",
    92: "Keypad 9", 65: "Keypad .", 67: "Keypad *",
    69: "Keypad +", 75: "Keypad /", 78: "Keypad -",
    76: "Keypad Enter", 81: "Keypad ="
]
