//
//  GameManager+tick.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI
import OrderedCollections

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
                segmentSwell * (
                    1 - exp(-3/activationTime * date.timeIntervalSince(state.lastChanged))
                )
            } else {
                // decreasing decay curve
                segmentSwell * (
                    exp(-3/deactivationTime * date.timeIntervalSince(state.lastChanged))
                )
            }
        }
        // "blur" the key heights
        let blurRadius = 1 // 1 samples on either side
        keyHeight = [:]
        func blur(layout: [String]) {
            for (index, key) in layout.enumerated() {
                let samples = ((-blurRadius + index)...(blurRadius + index)).compactMap { sampleIndex in
                    if 0 <= sampleIndex && sampleIndex < layout.count {
                        newKeyHeight[layout[sampleIndex]] ?? 0
                    } else { nil }
                }
                keyHeight[key] = samples.reduce(0, +) / CGFloat(samples.count)
            }
        }
        // we blur the LHS and RHS of the monster seperately
        blur(layout: Array(keyLayout[..<(keyLayout.count / 2)]))
        blur(layout: Array(keyLayout[(keyLayout.count / 2)...]))

        // we have the bezier, but also add points for the canvas's and the monster's LHS and RHS.
        let points: [CGPoint] = [
            CGPoint(x: 0, y: 0), // leftmost point
            CGPoint(x: monsterLocation + segmentWidth / 2, y: 0), // leftmost monster location
            CGPoint(x: monsterLocation + monsterWidth - segmentWidth / 2, y: 0), // rightmost monster location
            CGPoint(x: segmentWidth * CGFloat(keyLayout.count) + monsterWidth, y: 0) // rightmost point
        ] + keyLayout.enumerated().map { (index, key) in CGPoint(x: keyLocations[key] ?? 0, y: keyHeight[key] ?? 0) } // beziers

        self.keyLine = .init(
            points: points.sorted(by: { $0.x < $1.x })
        ) ?? .init(start: .zero, segments: [])
    }

    private func calculateVelocities(dt: TimeInterval) {
        // calculate velocity of boat
        for (id, boat) in boats {
            if let newBoat = update(boat: boat, dt: dt) {
                boats[id] = newBoat
            } else {
                boats.removeValue(forKey: id)
            }
        }
    }

    private func update(boat: Boat, dt: TimeInterval) -> Boat? {
        var newBoat = boat

        // we only check the waves if the boat is alive
        let boatInBounds: Bool = keyLine.segments.last != nil
            && keyLine.start.x <= newBoat.coordinate.x
            && newBoat.coordinate.x < keyLine.segments.last!.end.x

        if boat.status == .alive {
            if boatInBounds {
                for (candidateIndex, segment) in keyLine.segments.enumerated() {
                    let start = if candidateIndex == 0 { keyLine.start } else { keyLine.segments[candidateIndex-1].end }
                    guard start.x <= newBoat.coordinate.x, newBoat.coordinate.x < segment.end.x else { continue }

                    let gradient = bezierGradient(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newBoat.coordinate.x
                    ) ?? 0

                    let yValue = bezierY(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newBoat.coordinate.x
                    ) ?? 0

                    newBoat.angle = .radians(-atan(gradient))
                    newBoat.velocity += newBoat.acceleration * sin(newBoat.angle.radians)
                    newBoat.coordinate.y = yValue

                    break
                }
            } else {
                newBoat.coordinate.y = 0
                newBoat.angle = .zero
            }

            // we only do drag when the boat is within bounds
            if boatInBounds {
                let speedDecay = newBoat.drag * abs(newBoat.velocity)
                let gravityDecay = max(0, newBoat.gravityLoss * (newBoat.coordinate.y - boat.coordinate.y))
                let totalDecay = speedDecay * dt + gravityDecay // gravity decay is already dY, which is a function of dT
                if newBoat.velocity > 0 {
                    newBoat.velocity = max(0, newBoat.velocity - totalDecay)
                } else if newBoat.velocity < 0 {
                    newBoat.velocity = min(0, newBoat.velocity + totalDecay)
                }
            }
        }

        newBoat.coordinate.x += newBoat.velocity * dt

        // determine the boat's status
        if boatInBounds {
            // if the boat's hitbox is inside the monster's mouth, it goes into the monster's mouth
            if monsterLocation < boat.coordinate.x, boat.coordinate.x < monsterLocation + monsterWidth {
                // boat is inside monster's mouth
                newBoat.status = .eaten
                newBoat.velocity = 0
                newBoat.coordinate.y -= 300 * dt // boat sinks at 300 points per second
                newBoat.angle += .degrees(360) * dt // and rotates at 1 rot/s

                // if the boat is under 100 points, delete it
                if newBoat.coordinate.y < -100 {
                    spawnNewBoat()
                    return nil
                }
            }
        } else {
            // check if the velocity is pointed outwards
            if newBoat.coordinate.x < segmentWidth/2, newBoat.velocity <= 0 {
                // boat is to the left of the canvas
                newBoat.status = .lost

                // speed up the boat to be 50 points per second
                newBoat.velocity = -50
                // if it is actually outside the bounds, just delete it
                if boat.coordinate.x < -0.5 * (screenSize.width - canvasWidth) {
                    spawnNewBoat()
                    return nil
                }
            } else if newBoat.coordinate.x > canvasWidth - segmentWidth/2, newBoat.velocity >= 0 {
                // boat is to the right of the canvas

                // speed up the boat to be 50 points per second
                newBoat.velocity = 50
                // if it is actually outside the bounds, just delete it
                if boat.coordinate.x > canvasWidth + 0.5 * (screenSize.width - canvasWidth) {
                    spawnNewBoat()
                    return nil
                }
            }
        }

        return newBoat
    }

    func spawnNewBoat() {
        let fromLeft = Bool.random()
        let startVelocity = CGFloat.random(in: 60..<100) * (fromLeft ? 1 : -1)
        let startCoordinate = fromLeft
            ? -0.5 * (screenSize.width - canvasWidth)
            : canvasWidth + 0.5 * (screenSize.width - canvasWidth)

        let newBoat = Boat(
            coordinate: .init(x: startCoordinate, y: 0),
            angle: .zero,
            velocity: startVelocity
        )

        boats[newBoat.id] = newBoat
    }
}
