//
//  MonsterView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 21/10/26.
//

import SwiftUI
import Combine

struct MonsterView: View {
    var gameTimer = Timer.publish(every: 1/60, on: .main, in: .default).autoconnect()
    var isEating: Bool = false

    @State var offset: TimeInterval = 0

    var frontOnly: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.opacity(0.01)

            let total: Int = 15

            // main body
            ZStack(alignment: .top) {
                ForEach(0..<(total+1), id: \.self) { index in
                    let percentage = 1 - CGFloat(index)/CGFloat(total)
                    let scale = 1.0 + percentage*percentage*percentage * 4
                    let movement = sin(2 * (5 * percentage - offset))

                    let horizontalScale = index == total ? 1 : 1 + 0.1 * movement

                    ZStack {
                        Ellipse()
                            .fill(Color(hue: percentage, saturation: 0.8, brightness: 1.0))
                        Ellipse()
                            .stroke(Color(hue: percentage, saturation: 0.8, brightness: 0.7), lineWidth: 1)
                    }
                    .frame(width: scale * monsterWidth * horizontalScale, height: scale * monsterWidth/3)
                    .offset(
                        y: -monsterWidth/3/2 + percentage * segmentSeaLevel + 5 * movement
                    )
                }
            }
            .padding(.horizontal, monsterWidth * 5)
            .reverseMask(alignment: .top) {
                if frontOnly {
                    Ellipse()
                        .frame(width: monsterWidth, height: monsterWidth/3)
                        .offset(
                            y: -monsterWidth/3/2 + 5 * sin(-2 * offset)
                        )
                }
            }
            .padding(.horizontal, -monsterWidth * 5)

            // throat
            ForEach(0..<5, id: \.self) { index in
                let percentage = CGFloat(index)/CGFloat(total)

                ZStack {
                    Ellipse()
                        .fill(Color(hue: percentage, saturation: 0.8, brightness: 0.4))
                    Ellipse()
                        .stroke(Color(hue: percentage, saturation: 0.8, brightness: 0.2), lineWidth: 1)
                }
                .frame(width: monsterWidth, height: monsterWidth/3)
                .offset(
                    y: -monsterWidth/3/2 + percentage * segmentSeaLevel + 5 * sin(2 * (5 * percentage - offset))
                )
            }
            .mask {
                if !frontOnly {
                    Ellipse()
                        .frame(width: monsterWidth, height: monsterWidth/3)
                        .offset(
                            y: -monsterWidth/3/2 + 5 * sin(-2 * offset)
                        )
                }
            }

            // teeth, which are positioned on top of the ellipse
            let teeth: Int = 20
            let toothSize: CGFloat = 1/5
            ZStack {
                ForEach(0..<teeth, id: \.self) { index in
                    let percentage = CGFloat(index)/CGFloat(teeth)
                    let toothHeight = isEating ? monsterWidth/6 : monsterWidth/3 * toothSize

                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: monsterWidth/3 - toothHeight)
                        ZStack(alignment: .top) {
                            Star(corners: 3, smoothness: 0.5)
                                .fill(Color.white)
                            Star(corners: 6, smoothness: 0.5)
                                .fill(Color(hue: percentage, saturation: 0.8, brightness: 0.2))
                                .scaleEffect(0.5, anchor: .top)
                        }
                        .mask {
                            Star(corners: 3, smoothness: 0.5)
                        }
                        .frame(width: monsterWidth * 1.2 / CGFloat(teeth), height: toothHeight)
                        .scaleEffect(
                            y: 1 + 0.2 * sin(8 * (5 * percentage - offset)),
                            anchor: .bottom
                        )
                    }
                    .animation(.easeIn(duration: 0.1), value: isEating)
                    .rotationEffect(.degrees(360) * percentage + .degrees(offset * 10))
                }
            }
            .frame(width: monsterWidth, height: monsterWidth/3)
            .reverseMask(alignment: .top) {
                if frontOnly {
                    Rectangle()
                        .frame(width: monsterWidth, height: monsterWidth/3/2)
                }
            }
            .scaleEffect(x: 3, y: 1)
            .offset(
                y: -monsterWidth/3/2 + 5 * sin(-2 * offset)
            )
        }
        .frame(width: monsterWidth, height: segmentSeaLevel)
        .onReceive(gameTimer) { _ in
            self.offset = Date.timeIntervalSinceReferenceDate
        }
    }
}

struct TentacleView: View {
    var manager: GameManager

    struct TentacleInfo {
        var baseAngleRad: CGFloat
        var scale: CGFloat
        var fillColor: Color
        var livesRequirement: Int
    }

    var body: some View {
        ZStack(alignment: .center) {
            ForEach([
                TentacleInfo(baseAngleRad: 10 * .pi / 180, scale: 0.8, fillColor: .red, livesRequirement: 3),
                TentacleInfo(baseAngleRad: 6 * .pi / 180, scale: 1.0, fillColor: .orange, livesRequirement: 2),
                TentacleInfo(baseAngleRad: 2 * .pi / 180, scale: 1.2, fillColor: .yellow, livesRequirement: 1),
                TentacleInfo(baseAngleRad: -2 * .pi / 180, scale: 1.2, fillColor: .green, livesRequirement: 2),
                TentacleInfo(baseAngleRad: -6 * .pi / 180, scale: 1.0, fillColor: .purple, livesRequirement: 3)
            ].enumerated(), id: \.offset) { _, info in
                let isAlive = manager.lives >= info.livesRequirement

                TentaclePair(
                    manager: manager,
                    height: 100,
                    baseAngleRad: info.baseAngleRad,
                    fillStyle: isAlive ? info.fillColor : Color.gray.opacity(0.8),
                    animate: isAlive
                )
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(info.scale * (isAlive ? 1 : 0.6))
                .animation(.easeInOut, value: isAlive)
            }
        }
        .frame(width: manager.canvasWidth, height: 200)
    }
}

struct TentaclePair: View {
    var manager: GameManager

    var height: CGFloat
    var baseAngleRad: CGFloat
    var fillStyle: Color

    var animate: Bool = true

    var body: some View {
        let maxThickness: CGFloat = 30

        Path { path in
            // we ditch the first and last as they are static
            guard manager.keyLine.segments.count > 2 else { return }

            let monsterMiddle = manager.monsterLocation + monsterWidth/2
            let monsterPoint = CGPoint(x: monsterMiddle, y: height)
            let leftOrigin = CGPoint(x: 0, y: height)
            let rightOrigin = CGPoint(x: manager.canvasWidth, y: height)
            let angleShiftRad = atan((maxThickness/2)/monsterMiddle) // opp / adj

            func noise(x: CGFloat) -> CGFloat {
                0.25 * maxThickness * sin(
                    baseAngleRad * 100 // randomish offset
                    + x / 40 // sine moves along length
                    + (x > monsterMiddle ? -1 : 1)          // invert direction of travel depending on side. Always travels outwards.
                    * (animate ? Date.timeIntervalSinceReferenceDate : 1)   // sine travels with time
                )
            }

            func rot(_ point: CGPoint, up: Bool) -> CGPoint {
                // rotate around edge origins to give thickness
                let stageA = if point.x < monsterMiddle {
                    rotate(.init(x: point.x, y: 0), around: leftOrigin, radians: angleShiftRad * (up ? 1 : -1))
                } else {
                    rotate(.init(x: point.x, y: 0), around: rightOrigin, radians: angleShiftRad * (up ? -1 : 1))
                }

                // rotate around center to give base angle
                let stageB = if point.x < monsterMiddle {
                    rotate(.init(x: stageA.x, y: stageA.y), around: monsterPoint, radians: -baseAngleRad)
                } else {
                    rotate(.init(x: stageA.x, y: stageA.y), around: monsterPoint, radians: baseAngleRad)
                }

                return .init(
                    x: point.x,
                    y: height / 2 // center line
                    - (animate ? point.y : 0) // original height
                    - stageB.y // rotated change in height
                    + noise(x: point.x) // wavy tentacle
                )
            }

            let line = Bezier(start: manager.keyLine.segments.first!.end, segments: manager.keyLine.segments.dropLast())

            path.move(to: rot(line.start, up: true))

            for segment in line.segments {
                path.addCurve(
                    to: rot(segment.end, up: true),
                    control1: rot(segment.control1, up: true),
                    control2: rot(segment.control2, up: true)
                )
            }

            for (index, segment) in line.segments.enumerated().reversed() {
                let endPoint = if index == 0 { line.start } else { line.segments[index-1].end }

                path.addCurve(
                    to: rot(endPoint, up: false),
                    control1: rot(segment.control2, up: false),
                    control2: rot(segment.control1, up: false)
                )
            }

            path.closeSubpath()
        }
        .fill(fillStyle)
        .frame(width: manager.canvasWidth, height: maxThickness)
    }
}

func rotate(
    _ point: CGPoint,
    around center: CGPoint,
    radians: CGFloat
) -> CGPoint {
    let dx = point.x - center.x
    let dy = point.y - center.y

    let cosAngle = cos(radians)
    let sinAngle = sin(radians)

    return CGPoint(
        x: center.x + dx * cosAngle - dy * sinAngle,
        y: center.y + dx * sinAngle + dy * cosAngle
    )
}

#Preview {
    ZStack(alignment: .top) {
        MonsterView()
            .border(Color.red, width: 1)
    }
    .padding(50)
}

extension View {
    @inlinable
    public func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask()
                        .blendMode(.destinationOut)
                }
        }
    }
}
