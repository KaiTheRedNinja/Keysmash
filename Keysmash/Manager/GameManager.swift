//
//  GameManager.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI
import CoreGraphics

let activationTime: TimeInterval = 1 // takes 1s to build up fully
let deactivationTime: TimeInterval = 0.5 // takes 0.5s to dissipate

@Observable
class GameManager {
    let keyLayout: [String]
    let keyLocations: [String: CGFloat] // the center of the wave segment
    var currentlyPressedKeys: [String: KeyState]
    var keyLine: Bezier

    let canvasWidth: CGFloat
    let monsterLocation: CGFloat // leftmost coordinate of the monster

    var boats: [Boat]

    @ObservationIgnored internal var keyHeight: [String: CGFloat]
    @ObservationIgnored internal var prevTick: Date?

    init(keysStr: String = "qazwsxedcrfvtgbyhnujmik,ol.p;/") {
        self.keyLayout = keysStr.map { String($0).uppercased() }
        precondition(keyLayout.count == Set(keyLayout).count, "Keysstr must not contain duplicates")

        let midpoint = keyLayout.count / 2
        self.keyLocations = .init(
            uniqueKeysWithValues: keyLayout.enumerated().map { (index, key) in
                (key, segmentWidth * (CGFloat(index) + 0.5) + (index >= midpoint ? monsterWidth : 0))
            }
        )
        self.canvasWidth = CGFloat(keyLayout.count) * segmentWidth + monsterWidth
        self.monsterLocation = CGFloat(midpoint) * segmentWidth

        self.currentlyPressedKeys = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, KeyState(isPressed: false, lastChanged: .distantPast)) }
        )
        self.keyHeight = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, segmentDefaultHeight) }
        )
        self.keyLine = .init(start: .zero, segments: [])
        self.boats = [
            .init(
                coordinate: .init(x: 0, y: segmentDefaultHeight),
                angle: .zero,
                velocity: 30 // 30 points per second
            )
        ]
    }

    func update(forEvent event: KeyEventInfo) {
        guard let oldState = currentlyPressedKeys[event.physicalKeyName] else {
            print("No physical key registered: \(event.physicalKeyName)")
            return
        }
        guard !event.isRepeat, oldState.isPressed != (event.phase == .down) else {
            // key repeats are ignored
            // and so are repeats of the same keyup/keydown call
            return
        }

        currentlyPressedKeys[event.physicalKeyName] = .init(
            isPressed: event.phase == .down,
            lastChanged: .now
        )
    }
}
