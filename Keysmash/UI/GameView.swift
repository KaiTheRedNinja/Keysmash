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

                Path { path in
                    let canvasMargin = (screenSize.width - manager.canvasWidth)/2

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

                MonsterView()
                    .padding(.bottom, -segmentSeaLevel)
                    .padding(.leading, manager.monsterLocation)
            }
            .padding(.bottom, segmentSeaLevel)
            .frame(width: manager.canvasWidth, height: screenSize.height, alignment: .bottom)
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

struct RockView: View {
    var rock: Rock

    var body: some View {
        Star(corners: 10, smoothness: 0.8)
            .fill(Color.gray)
            .frame(width: 60, height: 60)
            .overlay {
                Text(String(format: "%.0f", rock.velocity))
            }
            .rotationEffect(rock.angle, anchor: .center)
            .animation(.interactiveSpring, value: rock.angle)
    }
}

struct MonsterView: View {
    var body: some View {
        Rectangle()
            .frame(width: monsterWidth, height: segmentSeaLevel)
    }
}

struct Star: Shape {
    // store how many corners the star has, and how smooth/pointed it is
    let corners: Int
    let smoothness: Double

    func path(in rect: CGRect) -> Path {
        // ensure we have at least two corners, otherwise send back an empty path
        guard corners >= 2 else { return Path() }

        // draw from the center of our rectangle
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)

        // start from directly upwards (as opposed to down or to the right)
        var currentAngle = -CGFloat.pi / 2

        // calculate how much we need to move with each star corner
        let angleAdjustment = .pi * 2 / Double(corners * 2)

        // figure out how much we need to move X/Y for the inner points of the star
        let innerX = center.x * smoothness
        let innerY = center.y * smoothness

        // we're ready to start with our path now
        var path = Path()

        // move to our initial position
        path.move(to: CGPoint(x: center.x * cos(currentAngle), y: center.y * sin(currentAngle)))

        // track the lowest point we draw to, so we can center later
        var bottomEdge: Double = 0

        // loop over all our points/inner points
        for corner in 0..<corners * 2  {
            // figure out the location of this point
            let sinAngle = sin(currentAngle)
            let cosAngle = cos(currentAngle)
            let bottom: Double

            // if we're a multiple of 2 we are drawing the outer edge of the star
            if corner.isMultiple(of: 2) {
                // store this Y position
                bottom = center.y * sinAngle

                // …and add a line to there
                path.addLine(to: CGPoint(x: center.x * cosAngle, y: bottom))
            } else {
                // we're not a multiple of 2, which means we're drawing an inner point

                // store this Y position
                bottom = innerY * sinAngle

                // …and add a line to there
                path.addLine(to: CGPoint(x: innerX * cosAngle, y: bottom))
            }

            // if this new bottom point is our lowest, stash it away for later
            if bottom > bottomEdge {
                bottomEdge = bottom
            }

            // move on to the next corner
            currentAngle += angleAdjustment
        }

        // figure out how much unused space we have at the bottom of our drawing rectangle
        let unusedSpace = (rect.height / 2 - bottomEdge) / 2

        // create and apply a transform that moves our path down by that amount, centering the shape vertically
        let transform = CGAffineTransform(translationX: center.x, y: center.y + unusedSpace)
        return path.applying(transform)
    }
}
