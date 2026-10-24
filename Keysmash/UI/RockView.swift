//
//  RockView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 21/10/26.
//

import SwiftUI

struct RockView: View {
    var rock: Rock

    @State var bouncing: Bool = false

    var body: some View {
        ZStack {
            Star(corners: rock.sideCount, smoothness: 0.85)
                .fill(Color.init(white: 0.7))
                .rotationEffect(.degrees(180 / CGFloat(rock.sideCount)))
            Star(corners: rock.sideCount, smoothness: 0.8)
                .fill(Color.init(white: 0.6))
            Star(corners: rock.sideCount, smoothness: 0.85)
                .fill(Color.init(white: 0.5))
                .padding(10)
            Star(corners: rock.sideCount, smoothness: 0.7)
                .fill(Color.init(white: 0.4))
                .padding(20)
        }
        .frame(width: 60, height: 60)
        .rotationEffect(rock.angle, anchor: .center)
        .animation(.interactiveSpring, value: rock.angle)
        .offset(y: bouncing ? 5 : 0)
        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bouncing)
        .onAppear {
            self.bouncing.toggle()
        }
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

#Preview {
    @Previewable @State var velocity: CGFloat = 100
    @Previewable @State var angle: CGFloat = 0
    @Previewable @State var sideCount: Int = 10

    VStack {
        RockView(
            rock: .init(
                coordinate: .init(),
                angle: .degrees(angle),
                velocity: velocity,
                sideCount: sideCount
            )
        )
        .padding(50)

        Slider(value: $velocity, in: -200...200)
        Slider(value: $angle, in: -45...45)
        Stepper("Side count", value: $sideCount, in: 6...12)
    }
}
