//
//  MonsterView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 21/10/26.
//

import SwiftUI

struct MonsterView: View {
    var body: some View {
        Rectangle()
            .frame(width: monsterWidth, height: segmentSeaLevel)
    }
}

struct TentacleView: View {
    var manager: GameManager

    var body: some View {
        ZStack(alignment: .center) {
            TentaclePair(manager: manager, height: 100, baseAngleRad: 10 * .pi / 180, fillStyle: Color.red)
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(0.8)
            TentaclePair(manager: manager, height: 100, baseAngleRad: 6 * .pi / 180, fillStyle: Color.orange)
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(1.0)
            TentaclePair(manager: manager, height: 100, baseAngleRad: 2 * .pi / 180, fillStyle: Color.yellow)
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(1.2)
            TentaclePair(manager: manager, height: 100, baseAngleRad: -2 * .pi / 180, fillStyle: Color.green)
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(1.2)
            TentaclePair(manager: manager, height: 100, baseAngleRad: -6 * .pi / 180, fillStyle: Color.purple)
                .frame(width: manager.canvasWidth, height: 200)
                .scaleEffect(1.0)
        }
        .frame(width: manager.canvasWidth, height: 200)
    }
}

struct TentaclePair: View {
    var manager: GameManager

    var height: CGFloat
    var baseAngleRad: CGFloat
    var fillStyle: Color

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
                    * Date.timeIntervalSinceReferenceDate   // sine travels with time
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
                    - point.y // original height
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
