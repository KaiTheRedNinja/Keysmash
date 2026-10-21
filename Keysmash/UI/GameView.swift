//
//  GameView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 20/10/26.
//

import SwiftUI
import Combine
import OrderedCollections

/// The width of a single wave segment
let segmentWidth: CGFloat = 40
/// The maximum height a wave can be, relative to sea level
let segmentSwell: CGFloat = 60
/// The sea level of the wave, relative to the bottom of the canvas
let segmentSeaLevel: CGFloat = 200
/// The total width of the monster
let monsterWidth: CGFloat = 40 * 3
/// The marign to the left and right of the monster where it wont count as its mouth hitbox
let monsterMargin: CGFloat = 20

/// The vertical misalignment of keys
let keyVerticalMisalignment: CGFloat = 20

struct GameView: View {
    @State var manager: GameManager = .init()
    var gameTimer = Timer.publish(every: 1/60, on: .main, in: .default).autoconnect()

    var yLevel: [String: Int] = .init(
        "QWERTYUIOP[]\\".map { (String($0), 0) } +
        "ASDFGHJKL;'".map { (String($0), 1) } +
        "ZXCVBNM,./".map { (String($0), 2) },
        uniquingKeysWith: { lhs, _ in lhs }
    )

    var body: some View {
        ZStack(alignment: .bottom) {
            Spacer()
                .frame(width: screenSize.width, height: screenSize.height, alignment: .center)

            Color.blue
                .frame(height: segmentSeaLevel)

            ZStack(alignment: .bottomLeading) {
                // back of monster's throat
                MonsterView(gameTimer: gameTimer, frontOnly: false)
                    .padding(.leading, manager.monsterLocation)
                    .frame(height: segmentSeaLevel, alignment: .topLeading)
                    .padding(.bottom, -segmentSeaLevel)

                ForEach(manager.boats.elements, id: \.key) { (_, boat) in
                    BoatView(boat: boat)
                        .scaleEffect(.init(floatLiteral: 1 + min(0, boat.coordinate.y / segmentSeaLevel)))
                        .offset(x: -50)
                        .offset(x: boat.coordinate.x, y: -boat.coordinate.y)
                }

                ForEach(manager.rocks.elements, id: \.key) { (_, rock) in
                    RockView(rock: rock)
                        .scaleEffect(.init(floatLiteral: 1 + min(0, rock.coordinate.y / segmentSeaLevel)))
                        .offset(x: -30, y: 20)
                        .offset(x: rock.coordinate.x, y: -rock.coordinate.y)
                }

                let canvasMargin = (screenSize.width - manager.canvasWidth)/2
                Path { path in
                    path.move(to: .init(x: -canvasMargin, y: 0))

                    path.addLine(to: manager.keyLine.start)

                    for segment in manager.keyLine.segments {
                        path.addCurve(
                            to: segment.end,
                            control1: segment.control1,
                            control2: segment.control2
                        )
                    }

                    path.addLine(to: .init(x: canvasMargin + (manager.keyLine.segments.last?.end.x ?? 0), y: 0))
                    path.addLine(to: .init(x: canvasMargin + (manager.keyLine.segments.last?.end.x ?? 0), y: -segmentSeaLevel))
                    path.addLine(to: .init(x: -canvasMargin, y: -segmentSeaLevel))
                    path.closeSubpath()
                }
                .scale(x: 1, y: -1) // vertically flip
                .fill(Color.blue.opacity(0.7))
                .frame(height: segmentSwell, alignment: .bottom)
                .padding(.bottom, segmentSeaLevel)
                .padding(.horizontal, canvasMargin)
                .reverseMask(alignment: .leading) {
                    Rectangle()
                        .frame(width: monsterWidth, height: segmentSwell + segmentSeaLevel)
                        .padding(.leading, manager.monsterLocation + canvasMargin)
                }
                .padding(.bottom, -segmentSeaLevel)
                .padding(.horizontal, -canvasMargin)

                ForEach(manager.keyLayout.enumerated(), id: \.offset) { (_, key) in
                    Text(key)
                        .padding(.bottom, 5)
                        .frame(
                            width: segmentWidth,
                            height: segmentWidth
                        )
                        .padding(.leading, (manager.keyLocations[key] ?? 0) - segmentWidth / 2)
                        .offset(y: segmentWidth - (manager.keyHeight[key] ?? 0) + CGFloat(yLevel[key] ?? 0) * keyVerticalMisalignment)
                }
            }
            .padding(.bottom, segmentSeaLevel)
            .frame(width: manager.canvasWidth, height: screenSize.height, alignment: .bottom)
            .overlay(alignment: .bottomLeading) {
                ZStack(alignment: .topLeading) {
                    TentacleView(manager: manager)
                        .frame(height: segmentSeaLevel, alignment: .topLeading)
                    MonsterView(gameTimer: gameTimer, frontOnly: true)
                        .padding(.leading, manager.monsterLocation)
                }
                .frame(height: segmentSeaLevel, alignment: .topLeading)
            }
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing) {
                    Text(String(repeating: "❤️", count: manager.lives))
                    Text("\(manager.points)")
                }
                .font(.largeTitle)
            }
        }
        .background {
            KeyCaptureView { event in
                manager.update(forEvent: event)
            }
        }
        .onReceive(gameTimer) { date in
            manager.tick(date: date)
        }
    }
}

