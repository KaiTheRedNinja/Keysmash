//
//  GameManager.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI

let activationTime: TimeInterval = 1 // takes 1s to build up fully
let deactivationTime: TimeInterval = 0.5 // takes 0.5s to dissipate

@Observable
class GameManager {
    let keyLayout: [String]
    var currentlyPressedKeys: [String: KeyState]
    var keyHeight: [String: CGFloat]

    var boats: [Boat]

    @ObservationIgnored
    private var prevTick: Date?

    struct KeyState: Hashable {
        var isPressed: Bool
        var lastChanged: Date
    }

    struct Boat: Identifiable, Hashable {
        var id: UUID = .init()
        // Coordinate of the bottom-center of the boat, offset from the bottom-left
        var coordinate: CGPoint
        // The angle of the boat, in clockwise degrees from flat
        var angle: Angle
        // The horizontal velocity of the boat (vertical position is determined by water level)
        var velocity: CGFloat
        // The maximum acceleration of the boat
        let acceleration: CGFloat = 20 // full acceleration is 20 units/s^2
        // The speed decay of the boat, in m/s^2
        let decay: CGFloat = 5
    }

    init(keysStr: String = "qazwsxedcrfvtgbyhnujmik,ol.p;/") {
        self.keyLayout = keysStr.map { String($0).uppercased() }
        precondition(keyLayout.count == Set(keyLayout).count, "Keysstr must not contain duplicates")

        self.currentlyPressedKeys = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, KeyState(isPressed: false, lastChanged: .distantPast)) }
        )
        self.keyHeight = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, segmentDefaultHeight) }
        )
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

    func tick(date: Date = .now) {
        defer { self.prevTick = date }

        // recalculate all key heights
        keyHeight = currentlyPressedKeys.mapValues { state in
            if state.isPressed {
                // increasing decay curve
                segmentDefaultHeight + (segmentRaisedHeight - segmentDefaultHeight) * (
                    1 - exp(-3/activationTime * date.timeIntervalSince(state.lastChanged))
                )
            } else {
                // decreasing decay curve
                segmentDefaultHeight + (segmentRaisedHeight - segmentDefaultHeight) * (
                    exp(-3/deactivationTime * date.timeIntervalSince(state.lastChanged))
                )
            }
        }

        // skip first tick for velocity calculations
        guard let prevTick else { return }
        let dt = date.timeIntervalSince(prevTick)

        // calculate velocity of boat
        for (arrayIndex, boat) in boats.enumerated() {
            var newBoat = boat

            // if the boat is within the wave area, update its velocity and angle accordingly
            let index = Int((boat.coordinate.x + 0.5) / segmentWidth)
            if 0 <= index, index <= keyLayout.count { // index is within the key layout
                // 0 = to the left of the leftmost key
                // keyLayout.count = to the right of the rightmost key

                let lhsHeight = if index > 0 {
                    keyHeight[keyLayout[index-1]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }
                let rhsHeight = if index < keyLayout.count {
                    keyHeight[keyLayout[index]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }

                let opp = rhsHeight - lhsHeight // height diff
                let gradient = opp / segmentWidth

                newBoat.angle = .radians(-atan(gradient))
                newBoat.velocity -= newBoat.acceleration * opp / sqrt(segmentWidth*segmentWidth + opp*opp) // opp / hyp

                let positionInIndex = (boat.coordinate.x + 0.5).remainder(dividingBy: segmentWidth) / segmentWidth
                newBoat.coordinate.y = (lhsHeight * (1 - positionInIndex)) + (rhsHeight * positionInIndex)
            } else {
                // collision detection - it went too far to either side, make it bounce with 50% decay in velocity and also return it
                newBoat.velocity *= -0.5
                newBoat.coordinate.x = max(0, min(newBoat.coordinate.x, segmentWidth * CGFloat(keyLayout.count)))
                newBoat.coordinate.y = segmentDefaultHeight

                newBoat.angle = .zero
            }
            newBoat.velocity -= newBoat.decay * dt

            newBoat.coordinate.x += newBoat.velocity * dt

            boats[arrayIndex] = newBoat
        }
    }
}
