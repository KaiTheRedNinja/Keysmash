//
//  BoatView.swift
//  Keysmash
//
//  Created by Kai Quan Tay on 21/10/26.
//

import SwiftUI

struct BoatView: View {
    var boat: Boat

    @State var bouncing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 20)

                ForEach(0..<3) { index in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 4, height: 60)

                        Path { path in
                            let sail1Height: CGFloat = 20
                            let sail2Height: CGFloat = 30

                            path.move(to: .init(x: 0, y: 0)) // move to top left
                            // top sail, inner
                            path.addQuadCurve(
                                to: .init(x: 0, y: sail1Height),
                                control: .init(x: 5, y: sail1Height/2)
                            )
                            // top sail, outer
                            path.addQuadCurve(
                                to: .init(x: 0, y: 0),
                                control: .init(x: 5 + min(150, abs(boat.velocity)) * sail1Height / 200, y: sail1Height/2)
                            )
                            path.closeSubpath()

                            // bottom sail, inner
                            path.move(to: .init(x: 0, y: sail1Height))
                            path.addQuadCurve(
                                to: .init(x: 0, y: sail1Height + sail2Height),
                                control: .init(x: 5, y: sail1Height + sail2Height/2)
                            )
                            // bottom sail, outer
                            path.addQuadCurve(
                                to: .init(x: 0, y: sail1Height),
                                control: .init(x: 5 + min(150, abs(boat.velocity)) * sail2Height / 200, y: sail1Height + sail2Height/2)
                            )
                            path.closeSubpath()
                        }
                        .fill(Color.white)
                        .frame(maxWidth: .infinity)
                    }
                    .scaleEffect(index == 1 ? 1 : 0.8, anchor: .bottom)
                }
            }
            .frame(width: 100, height: 60)
            .scaleEffect(x: boat.velocity < 0 ? -1 : 1) // flip mast and sail if moving left
            UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 10, bottomTrailing: 10))
                .fill(Color.brown)
                .frame(width: 100, height: 20)
                .overlay {
                    HStack {
                        ForEach(0..<6) { _ in
                            ZStack {
                                Circle()
                                    .fill(Color.gray)
                                Circle()
                                    .stroke(Color.black, lineWidth: 1)
                            }
                            .frame(width: 6, height: 6)
                            .padding(.bottom, 3)
                        }
                    }
                }
        }
        .rotationEffect(boat.angle, anchor: .bottom)
        .animation(.interactiveSpring, value: boat.angle)
        .offset(y: bouncing ? 5 : 0)
        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bouncing)
        .onAppear {
            self.bouncing.toggle()
        }
    }
}

#Preview {
    @Previewable @State var velocity: CGFloat = 100
    @Previewable @State var angle: CGFloat = 0

    VStack {
        BoatView(
            boat: .init(
                coordinate: .init(),
                angle: .degrees(angle),
                velocity: velocity
            )
        )
        .padding(50)

        Slider(value: $velocity, in: -200...200)
        Slider(value: $angle, in: -45...45)
    }
}
