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

        self.keyLine = .init(points: (
            [CGPoint(x: 0, y: segmentDefaultHeight)] +
            keyLayout.enumerated()
                .map { (index, key) in CGPoint(x: segmentWidth * (CGFloat(index) + 0.5), y: keyHeight[key] ?? 0) } +
            [CGPoint(x: segmentWidth * CGFloat(keyLayout.count), y: segmentDefaultHeight)]
        )) ?? .init(start: .zero, segments: [])
    }

    private func calculateVelocities(dt: TimeInterval) {
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

            let decay = newBoat.decay + max(0, newBoat.gravityLoss * (newBoat.coordinate.y - boat.coordinate.y))
            if newBoat.velocity > 0 {
                newBoat.velocity = max(0, newBoat.velocity - decay * dt)
            } else if newBoat.velocity < 0 {
                newBoat.velocity = min(0, newBoat.velocity + decay * dt)
            }

            newBoat.coordinate.x += newBoat.velocity * dt

            boats[arrayIndex] = newBoat
        }
    }
}
