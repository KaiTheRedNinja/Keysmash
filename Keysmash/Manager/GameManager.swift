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
    var currentlyPressedKeys: [String: KeyState]
    var keyHeight: [String: CGFloat]
    var keyLine: Bezier

    var boats: [Boat]

    @ObservationIgnored
    private var prevTick: Date?

    struct KeyState: Hashable {
        var isPressed: Bool
        var lastChanged: Date
    }

    struct Bezier {
        var start: CGPoint
        var segments: [BezierSegment]
    }

    struct BezierSegment {
        var control1: CGPoint
        var control2: CGPoint
        var end: CGPoint
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

    func tick(date: Date = .now) {
        defer { self.prevTick = date }

        // recalculate all key heights
        let newKeyHeight = currentlyPressedKeys.mapValues { state in
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
        // "blur" the key heights
        let blurRadius = 1 // 1 samples on either side
        keyHeight = [:]
        for (index, key) in keyLayout.enumerated() {
            let samples = ((-blurRadius + index)...(blurRadius + index)).compactMap { sampleIndex in
                if 0 <= sampleIndex && sampleIndex < keyLayout.count {
                    newKeyHeight[keyLayout[sampleIndex]] ?? segmentDefaultHeight
                } else { nil }
            }
            keyHeight[key] = samples.reduce(0, +) / CGFloat(samples.count)
        }

        calculateKeyBezier()

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

                // get the bezier
                let bezier = keyLine.segments[index]
                let start = if index == 0 { keyLine.start } else { keyLine.segments[index-1].end }

                let gradient = bezierGradient(
                    p0: start,
                    c1: bezier.control1,
                    c2: bezier.control2,
                    p1: bezier.end,
                    atX: newBoat.coordinate.x
                )!

                // get the heights for naive interpolation
                let lhsHeight = if index > 0 {
                    keyHeight[keyLayout[index-1]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }
                let rhsHeight = if index < keyLayout.count {
                    keyHeight[keyLayout[index]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }
                let opp = rhsHeight - lhsHeight // height diff

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

    func calculateKeyBezier() {
        let points = (
            [CGPoint(x: 0, y: segmentDefaultHeight)] +
            keyLayout.enumerated()
                .map { (index, key) in CGPoint(x: segmentWidth * (CGFloat(index) + 0.5), y: keyHeight[key] ?? 0) } +
            [CGPoint(x: segmentWidth * CGFloat(keyLayout.count), y: segmentDefaultHeight)]
        )

        guard let first = points.first else { return }

        var segments: [BezierSegment] = []

        guard points.count > 1 else { return }

        // draw a smooth line
        for i in 0..<(points.count - 1) {
            let current = points[i]
            let next = points[i + 1]

            let previous = i > 0 ? points[i - 1] : current
            let following = i + 2 < points.count
            ? points[i + 2]
            : next

            let tension: CGFloat = 1.0 / 6.0

            let control1 = CGPoint(
                x: current.x + (next.x - previous.x) * tension,
                y: current.y + (next.y - previous.y) * tension
            )

            let control2 = CGPoint(
                x: next.x - (following.x - current.x) * tension,
                y: next.y - (following.y - current.y) * tension
            )

            segments.append(.init(control1: control1, control2: control2, end: next))
        }

        self.keyLine = .init(start: first, segments: segments)
    }
}

func bezierGradient(
    p0: CGPoint,
    c1: CGPoint,
    c2: CGPoint,
    p1: CGPoint,
    atX targetX: CGFloat
) -> CGFloat? {
    // Find t such that the Bézier curve's x coordinate
    // equals targetX. Binary search works when x(t) is monotonic.
    var low: CGFloat = 0
    var high: CGFloat = 1

    for _ in 0..<40 {
        let t = (low + high) / 2
        let u = 1 - t

        let x = u * u * u * p0.x
        + 3 * u * u * t * c1.x
        + 3 * u * t * t * c2.x
        + t * t * t * p1.x

        if x < targetX {
            low = t
        } else {
            high = t
        }
    }

    let t = (low + high) / 2
    let u = 1 - t

    let dx = 3 * u * u * (c1.x - p0.x)
    + 6 * u * t * (c2.x - c1.x)
    + 3 * t * t * (p1.x - c2.x)

    let dy = 3 * u * u * (c1.y - p0.y)
    + 6 * u * t * (c2.y - c1.y)
    + 3 * t * t * (p1.y - c2.y)

    guard abs(dx) > 1e-10 else {
        return nil
    }

    return dy / dx
}
