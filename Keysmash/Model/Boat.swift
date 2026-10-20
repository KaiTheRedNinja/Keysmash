//
//  Boat.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI

struct Boat: Identifiable, Hashable {
    var id: UUID = .init()
    // Coordinate of the bottom-center of the boat, offset from the bottom-left
    var coordinate: CGPoint
    // The angle of the boat, in clockwise degrees from flat
    var angle: Angle
    // The horizontal velocity of the boat (vertical position is determined by water level)
    var velocity: CGFloat
    // Whether the boat has been eaten, freed, or is still in play
    var status: BoatStatus = .alive
    // The maximum acceleration of the boat, in point/s^2. Must be larger than decay.
    let acceleration: CGFloat = 15
    // The drag coefficient. a = vD, so v = v - vD * dt
    let drag: CGFloat = 0.5
    // The gravity loss of the boat, in point/s per point
    let gravityLoss: CGFloat = 1 // lose 1 point/s per point of height gained

    enum BoatStatus {
        /// Boat is still in play
        case alive
        /// Boat has exited the bounds of the game
        case lost
        /// Boat has been eaten by the monster
        case eaten
    }
}
