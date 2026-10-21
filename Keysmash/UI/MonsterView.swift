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
        let height: CGFloat = 200
        let maxThickness: CGFloat = 30
        let baseAngleRad: CGFloat = 5 * .pi / 180 // 5 deg

        Path { path in
            // we ditch the first and last as they are static
            guard manager.keyLine.segments.count > 2 else { return }

            let monsterMiddle = manager.monsterLocation + monsterWidth/2
            let leftOrigin = CGPoint(x: 0, y: height/2)
            let rightOrigin = CGPoint(x: manager.canvasWidth, y: height/2)
            let angleShiftRad = atan((maxThickness/2)/monsterMiddle) // opp / adj

            func noise(x: CGFloat) -> CGFloat {
                0.25 * maxThickness * sin(
                    x / 40 // sine moves along length
                    + (x > monsterMiddle ? -1 : 1)          // invert direction of travel depending on side. Always travels outwards.
                    * Date.timeIntervalSinceReferenceDate   // sine travels with time
                )
            }

            func rot(_ point: CGPoint, up: Bool) -> CGPoint {
                let newPoint = if point.x < monsterMiddle {
                    rotate(.init(x: point.x, y: 0), around: leftOrigin, radians: angleShiftRad * (up ? 1 : -1) - baseAngleRad)
                } else {
                    rotate(.init(x: point.x, y: 0), around: rightOrigin, radians: angleShiftRad * (up ? -1 : 1) + baseAngleRad)
                }

                return .init(
                    x: point.x,
                    y: height / 2 // center line
                        - point.y // original height
                        - newPoint.y // rotated change in height
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
        .fill(Color.red)
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
