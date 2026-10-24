//
//  GameManager.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 19/10/26.
//

import SwiftUI
import CoreGraphics
import Collections

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

    var boats: OrderedDictionary<UUID, Boat>
    var rocks: OrderedDictionary<UUID, Rock>

    /// The current game status
    var gameStatus: GameStatus = .playing
    /// The current stats
    var gameStats: GameStats = .zero
    /// The number of lives you have. You lose one every time you eat a rock.
    var lives: Int = 3
    /// The number of points you have. You gain
    /// - +5 for each boat eaten
    /// - +1 for each rock freed
    /// - -3 for each boat freed
    var points: Int = 0
    /// Whether the monster is currently eating
    var isEating: Bool = false

    /// The current tutorial state, if a tutorial is currently active
    var tutorial: TutorialState? = .boatTarget

    /// The number of boats and rocks on screen at any given point.
    /// If the total number of boats and rocks is lower than this number, one is
    /// created at random.
    ///
    /// It is determined by the formula `1 + sqrt(points / 5)`. This starts at 1, and increases to:
    /// - 2 at 5 points
    /// - 3 at 20 points
    /// - 4 at 45 points
    /// - 5 at 80 points
    /// - N at `5(N-1)^2` points
    var concurrentEatables: Int {
        1 + Int(sqrt(max(0, CGFloat(points)) / 5))
    }

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
                .map { ($0, 0) }
        )
        self.keyLine = .init(start: .zero, segments: [])
        self.boats = [:]
        self.rocks = [:]

        checkEatableCount()
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

    func revive() {
        self.rocks = [:]
        self.boats = [:]
        self.lives = 3
        self.points = 0
        self.isEating = false
        self.gameStatus = .playing
        self.gameStats = .zero
    }
}

enum GameStatus {
    case playing
    case dead
}

struct GameStats: Equatable {
    var boatsEaten: Int
    var boatsLost: Int
    var rocksEaten: Int
    var rocksAvoided: Int

    static let zero = GameStats(boatsEaten: 0, boatsLost: 0, rocksEaten: 0, rocksAvoided: 0)
}
