//
//  Boat.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI

protocol Eatable: Identifiable, Hashable {
    var id: UUID { get }
    /// Coordinate of the bottom-center of the eatable, offset from the bottom-left of the canvas
    var coordinate: CGPoint { get set }
    /// The angle of the eatable, in clockwise degrees from flat
    var angle: Angle { get set }
    /// The horizontal velocity of the eatable (vertical position is determined by water level)
    var velocity: CGFloat { get set }
    /// Whether the eatable has been eaten, lost, or is still in play
    var status: EatableStatus { get set }

    /// How the angle behaves
    var angleBehaviour: AngleBehaviour { get }

    /// The maximum acceleration of the eatable, in point/s^2. Must be larger than decay.
    var acceleration: CGFloat { get }
    /// The drag coefficient
    var drag: CGFloat { get }
    /// The gravity loss of the eatable, in point/s per point
    var gravityLoss: CGFloat { get }
}

enum EatableStatus {
    /// Boat is still in play
    case alive
    /// Boat has exited the bounds of the game
    case lost
    /// Boat has been eaten by the monster
    case eaten
}

enum AngleBehaviour {
    /// The angle is the angle of the wave
    case followsWave
    /// The angle increases with velocity
    case followsVelocity
}

struct Boat: Eatable {
    var id: UUID = .init()
    var coordinate: CGPoint
    var angle: Angle
    var velocity: CGFloat
    var status: EatableStatus = .alive

    var angleBehaviour: AngleBehaviour { .followsWave }
    let acceleration: CGFloat = 15
    let drag: CGFloat = 0.5
    let gravityLoss: CGFloat = 1 // lose 1 point/s per point of height gained
}

struct Rock: Eatable {
    var id: UUID = .init()
    var coordinate: CGPoint
    var angle: Angle
    var velocity: CGFloat
    var status: EatableStatus = .alive

    var angleBehaviour: AngleBehaviour { .followsVelocity }
    let acceleration: CGFloat = 15
    let drag: CGFloat = 0.1
    let gravityLoss: CGFloat = 1
}
