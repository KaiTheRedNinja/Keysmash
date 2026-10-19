//
//  Keys.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

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

struct KeyState: Hashable {
    var isPressed: Bool
    var lastChanged: Date
}
