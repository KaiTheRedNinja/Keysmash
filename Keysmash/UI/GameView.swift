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
let segmentSeaLevel: CGFloat = 300
/// The total width of the monster
let monsterWidth: CGFloat = 40 * 3

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

            ZStack(alignment: .bottomLeading) {
                Path { path in
                    path.move(to: manager.keyLine.start)

                    for segment in manager.keyLine.segments {
                        path.addCurve(
                            to: segment.end,
                            control1: segment.control1,
                            control2: segment.control2
                        )
                    }

                    path.addLine(to: .init(x: manager.keyLine.segments.last?.end.x ?? 0, y: -segmentSeaLevel))
                    path.addLine(to: .init(x: 0, y: -segmentSeaLevel))
                    path.closeSubpath()
                }
                .scale(x: 1, y: -1) // vertically flip
                .fill(Color.blue.opacity(0.8))
                .frame(height: segmentSwell, alignment: .bottom)

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

                ForEach(manager.boats.elements, id: \.key) { (_, boat) in
                    BoatView(boat: boat)
                        .offset(x: -50)
                        .offset(x: boat.coordinate.x, y: -boat.coordinate.y)
                }

                MonsterView()
                    .padding(.bottom, -segmentSeaLevel)
                    .padding(.leading, manager.monsterLocation)
            }
            .frame(width: manager.canvasWidth)
            .border(Color.purple)
            .padding(.bottom, segmentSeaLevel)
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

struct BoatView: View {
    var boat: Boat

    var body: some View {
        UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 10, bottomTrailing: 10))
            .fill(Color.brown)
            .frame(width: 100, height: 20)
            .overlay {
                Text(String(format: "%.0f", boat.velocity))
            }
            .rotationEffect(boat.angle, anchor: .bottom)
            .animation(.interactiveSpring, value: boat.angle)
    }
}

struct MonsterView: View {
    var body: some View {
        Rectangle()
            .frame(width: monsterWidth, height: segmentSeaLevel)
    }
}
