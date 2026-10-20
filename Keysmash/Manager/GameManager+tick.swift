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
            if let newBoat = update(eatable: boat, dt: dt) {
                boats[id] = newBoat
            } else {
                boats.removeValue(forKey: id)
            }
        }
        // calculate velocity of rocks
        for (id, rock) in rocks {
            if let newRock = update(eatable: rock, dt: dt) {
                rocks[id] = newRock
            } else {
                rocks.removeValue(forKey: id)
            }
        }

        // if we have run out of boats/rocks, spawn another one
        if boats.isEmpty { spawnNewBoat() }
        if rocks.isEmpty { spawnNewRock() }
    }

    private func update<E: Eatable>(eatable: E, dt: TimeInterval) -> E? {
        var newEatable = eatable

        // we only check the waves if the boat is alive
        let boatInBounds: Bool = keyLine.segments.last != nil
            && keyLine.start.x <= newEatable.coordinate.x
            && newEatable.coordinate.x < keyLine.segments.last!.end.x

        if eatable.status == .alive {
            if boatInBounds {
                for (candidateIndex, segment) in keyLine.segments.enumerated() {
                    let start = if candidateIndex == 0 { keyLine.start } else { keyLine.segments[candidateIndex-1].end }
                    guard start.x <= newEatable.coordinate.x, newEatable.coordinate.x < segment.end.x else { continue }

                    let gradient = bezierGradient(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newEatable.coordinate.x
                    ) ?? 0

                    let yValue = bezierY(
                        p0: start,
                        c1: segment.control1,
                        c2: segment.control2,
                        p1: segment.end,
                        atX: newEatable.coordinate.x
                    ) ?? 0

                    let angle = Angle.radians(-atan(gradient))
                    if eatable.angleBehaviour == .followsWave {
                        newEatable.angle = angle
                    }
                    newEatable.velocity += newEatable.acceleration * sin(angle.radians)
                    newEatable.coordinate.y = yValue

                    break
                }
            } else {
                newEatable.coordinate.y = 0
                if eatable.angleBehaviour == .followsWave {
                    newEatable.angle = .zero
                }
            }

            // we only do drag when the boat is within bounds
            if boatInBounds {
                let speedDecay = newEatable.drag * abs(newEatable.velocity)
                let gravityDecay = max(0, newEatable.gravityLoss * (newEatable.coordinate.y - eatable.coordinate.y))
                let totalDecay = speedDecay * dt + gravityDecay // gravity decay is already dY, which is a function of dT
                if newEatable.velocity > 0 {
                    newEatable.velocity = max(0, newEatable.velocity - totalDecay)
                } else if newEatable.velocity < 0 {
                    newEatable.velocity = min(0, newEatable.velocity + totalDecay)
                }
            }
        }

        newEatable.coordinate.x += newEatable.velocity * dt
        if eatable.angleBehaviour == .followsVelocity {
            newEatable.angle += .radians(newEatable.velocity / 50) * dt // angular velocity = v/L
        }

        // determine the boat's status
        if boatInBounds {
            // if the boat's hitbox is inside the monster's mouth, it goes into the monster's mouth
            if monsterLocation + monsterMargin < eatable.coordinate.x,
               eatable.coordinate.x < monsterLocation + monsterWidth - monsterMargin {
                // boat is inside monster's mouth
                if newEatable.status != .eaten {
                    newEatable.velocity = 0
                }
                newEatable.status = .eaten
                newEatable.coordinate.x = eatable.coordinate.x // undo horizontal velocity
                newEatable.velocity += 300 * dt
                newEatable.coordinate.y -= newEatable.velocity * dt // boat sinks at 300 points/s^2
                if eatable.angleBehaviour == .followsWave {
                    newEatable.angle += .degrees(360) * dt * (newEatable.coordinate.x < canvasWidth/2 ? 1 : -1) // and rotates at 1 rot/s
                }

                // if the boat is under the sea, delete it
                if newEatable.coordinate.y < -segmentSeaLevel {
                    return nil
                }
            }
        } else {
            // check if the velocity is pointed outwards
            if newEatable.coordinate.x < segmentWidth/2, newEatable.velocity <= 0 {
                // boat is to the left of the canvas
                newEatable.status = .lost

                // speed up the boat to be at least 50 points per second
                newEatable.velocity = min(newEatable.velocity, -50)
                // if it is actually outside the bounds, just delete it
                if eatable.coordinate.x < -0.5 * (screenSize.width - canvasWidth) {
                    return nil
                }
            } else if newEatable.coordinate.x > canvasWidth - segmentWidth/2, newEatable.velocity >= 0 {
                // boat is to the right of the canvas

                // speed up the boat to be at least 50 points per second
                newEatable.velocity = max(newEatable.velocity, 50)
                // if it is actually outside the bounds, just delete it
                if eatable.coordinate.x > canvasWidth + 0.5 * (screenSize.width - canvasWidth) {
                    return nil
                }
            }
        }

        return newEatable
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

    func spawnNewRock() {
        let fromLeft = Bool.random()
        let startVelocity = CGFloat.random(in: 100..<200) * (fromLeft ? 1 : -1)
        let startCoordinate = fromLeft
        ? -0.5 * (screenSize.width - canvasWidth)
        : canvasWidth + 0.5 * (screenSize.width - canvasWidth)

        let newRock = Rock(
            coordinate: .init(x: startCoordinate, y: 0),
            angle: .zero,
            velocity: startVelocity
        )

        rocks[newRock.id] = newRock
    }
}
