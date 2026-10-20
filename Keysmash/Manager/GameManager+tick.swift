//
//  GameManager+tick.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI

extension GameManager {
    func tick(date: Date = .now) {
        defer { self.prevTick = date }

        calculateHeights(date: date)

        // skip first tick for velocity calculations
        guard let prevTick else { return }
        let dt = date.timeIntervalSince(prevTick)

        calculateVelocities(dt: dt)
    }

    private func calculateHeights(date: Date) {
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

        // we have the bezier, but also add points for the canvas's and the monster's LHS and RHS.
        let points: [CGPoint] = [
            CGPoint(x: 0, y: segmentDefaultHeight), // leftmost point
            CGPoint(x: monsterLocation + segmentWidth / 2, y: segmentDefaultHeight), // leftmost monster location
            CGPoint(x: monsterLocation + monsterWidth - segmentWidth / 2, y: segmentDefaultHeight), // rightmost monster location
            CGPoint(x: segmentWidth * CGFloat(keyLayout.count) + monsterWidth, y: segmentDefaultHeight) // rightmost point
        ] + keyLayout.enumerated().map { (index, key) in CGPoint(x: keyLocations[key] ?? 0, y: keyHeight[key] ?? 0) } // beziers

        self.keyLine = .init(
            points: points.sorted(by: { $0.x < $1.x })
        ) ?? .init(start: .zero, segments: [])
    }

    private func calculateVelocities(dt: TimeInterval) {
        // calculate velocity of boat
        for (arrayIndex, boat) in boats.enumerated() {
            var newBoat = boat

            if let last = keyLine.segments.last, keyLine.start.x <= newBoat.coordinate.x, newBoat.coordinate.x < last.end.x {
                for (candidateIndex, segment) in keyLine.segments.enumerated() {
                    let start = if candidateIndex == 0 { keyLine.start } else { keyLine.segments[candidateIndex-1].end }
                    guard start.x <= newBoat.coordinate.x, newBoat.coordinate.x < segment.end.x else { continue }

                    let gradient = bezierGradient(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newBoat.coordinate.x
                    )!

                    let yValue = bezierY(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newBoat.coordinate.x
                    ) ?? segmentDefaultHeight

                    newBoat.angle = .radians(-atan(gradient))
                    newBoat.velocity += newBoat.acceleration * sin(newBoat.angle.radians)
                    newBoat.coordinate.y = yValue
                }
            } else {
                // collision detection - it went too far to either side, make it bounce with 50% decay in velocity and also return it
                newBoat.velocity *= -0.5
                newBoat.coordinate.x = max(0, min(newBoat.coordinate.x, segmentWidth * CGFloat(keyLayout.count)))
                newBoat.coordinate.y = segmentDefaultHeight

                newBoat.angle = .zero
            }

            let speedDecay = newBoat.drag * abs(newBoat.velocity)
            let gravityDecay = max(0, newBoat.gravityLoss * (newBoat.coordinate.y - boat.coordinate.y))
            let totalDecay = speedDecay * dt + gravityDecay // gravity decay is already dY, which is a function of dT
            if newBoat.velocity > 0 {
                newBoat.velocity = max(0, newBoat.velocity - totalDecay)
            } else if newBoat.velocity < 0 {
                newBoat.velocity = min(0, newBoat.velocity + totalDecay)
            }

            newBoat.coordinate.x += newBoat.velocity * dt

            boats[arrayIndex] = newBoat
        }
    }
}
