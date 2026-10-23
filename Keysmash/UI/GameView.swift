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

    @State var currentOffset: TimeInterval = 0

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

            VStack {
                Spacer()
                    .frame(height: 300)

                Text("Keysmash")
                    .font(.system(size: 100, design: .serif))
                Text("Spam your keys to control the waves")
                    .font(.system(size: 30))
                Text("Eat boat. Avoid rock.")
                    .font(.system(size: 30))

                Spacer()
                    .frame(height: 50)

                switch manager.tutorial {
                case nil: EmptyView()
                case .boatTarget:
                    Text("You are Charybdis, the whirlpool monster.").font(.system(size: 20))
                    Text("Use the waves to push the boat towards you!").font(.system(size: 20))
                case .rockTarget:
                    Text("Rocks hurt you. Use the waves to push rocks away.").font(.system(size: 20))
                case .rockTargetTryAgain:
                    Text("DONT EAT ROCKS!!! You'll lose lives next time >:(").font(.system(size: 20))
                    Text("Rocks hurt you. Use the waves to push rocks away.").font(.system(size: 20))
                case .transition:
                    Text("Good luck! Even more rocks and boats will start spawning....").font(.system(size: 20))
                }

                if manager.tutorial != nil {
                    Spacer()
                        .frame(height: 50)

                    Button {
                        manager.tutorial = nil
                    } label: {
                        Text("Skip Tutorial")
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(nsColor: .selectedContentBackgroundColor))
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: screenSize.height, alignment: .top)

            // passive swell
            ForEach(3..<5) { multiple in
                let scale = CGFloat(multiple)

                Path { path in
                    let passiveSwell: CGFloat = 5
                    let sampleCount = 100

                    path.move(to: .init(x: 0, y: 0))
                    for sampleIndex in 0...sampleCount {
                        let percent = CGFloat(sampleIndex)/CGFloat(sampleCount)
                        let height = passiveSwell * sin(scale * (
                            0.5 * CGFloat(sampleIndex) +
                            (percent > 0.5 ? 1 : -1) * 2 * currentOffset
                        ))
                        path.addLine(to: .init(x: screenSize.width * percent, y: height - passiveSwell))
                    }
                    path.addLine(to: .init(x: screenSize.width, y: 0))
                    path.addLine(to: .init(x: screenSize.width, y: segmentSeaLevel))
                    path.addLine(to: .init(x: 0, y: segmentSeaLevel))
                    path.addLine(to: .init(x: 0, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.8))
                .frame(height: segmentSeaLevel)
            }

            ZStack(alignment: .bottomLeading) {
                // back of monster's throat
                MonsterView(gameTimer: gameTimer, isEating: manager.isEating, frontOnly: false)
                    .padding(.leading, manager.monsterLocation)
                    .frame(height: segmentSeaLevel, alignment: .topLeading)
                    .padding(.bottom, -segmentSeaLevel)

                ForEach(manager.boats.elements, id: \.key) { (_, boat) in
                    BoatView(boat: boat)
                        .scaleEffect(.init(floatLiteral: 1 + min(0, boat.coordinate.y / segmentSeaLevel)))
                        .overlay(alignment: .top) {
                            if manager.tutorial != nil {
                                Text("EAT ME!").font(.system(size: 20)).multilineTextAlignment(.center)
                                    .offset(y: -80)
                            }
                        }
                        .offset(x: -50)
                        .offset(x: boat.coordinate.x, y: -boat.coordinate.y)
                }

                ForEach(manager.rocks.elements, id: \.key) { (_, rock) in
                    RockView(rock: rock)
                        .scaleEffect(.init(floatLiteral: 1 + min(0, rock.coordinate.y / segmentSeaLevel)))
                        .overlay(alignment: .top) {
                            if manager.tutorial != nil {
                                Text("DONT EAT!").font(.system(size: 20)).multilineTextAlignment(.center)
                                    .offset(y: -80)
                            }
                        }
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
                    MonsterView(gameTimer: gameTimer, isEating: manager.isEating, frontOnly: true)
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
            currentOffset = Date.timeIntervalSinceReferenceDate
        }
    }
}

