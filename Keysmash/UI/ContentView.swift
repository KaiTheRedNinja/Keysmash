import SwiftUI
import Combine

let segmentWidth: CGFloat = 20
let segmentDefaultHeight: CGFloat = 30
let segmentRaisedHeight: CGFloat = 60

struct ContentView: View {
    @State var manager: GameManager = .init()
    var gameTimer = Timer.publish(every: 1/60, on: .main, in: .default).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(manager.keyLayout.enumerated(), id: \.offset) { (_, key) in
                Text(key)
                    .padding(.bottom, 5)
                    .frame(
                        width: segmentWidth,
                        height: manager.keyHeight[key] ?? 0
                    )
            }
        }
        .frame(height: segmentRaisedHeight, alignment: .bottom)
        .background {
            Path { path in
                path.move(to: manager.keyLine.start)

                for segment in manager.keyLine.segments {
                    path.addCurve(
                        to: segment.end,
                        control1: segment.control1,
                        control2: segment.control2
                    )
                }

                path.addLine(to: .init(x: manager.keyLine.segments.last?.end.x ?? 0, y: 0))
                path.addLine(to: .init(x: 0, y: 0))
                path.closeSubpath()
            }
            .scale(x: 1, y: -1) // vertically flip
            .fill(Color.blue.opacity(0.8))
            .frame(height: segmentRaisedHeight, alignment: .bottom)
        }
        .overlay(alignment: .bottomLeading) {
            ForEach(manager.boats) { boat in
                UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 10, bottomTrailing: 10))
                    .fill(Color.brown)
                    .frame(width: 100, height: 20)
                    .rotationEffect(boat.angle, anchor: .bottom)
                    .animation(.interactiveSpring, value: boat.angle)
                    .offset(x: -50)
                    .offset(x: boat.coordinate.x, y: -boat.coordinate.y)
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
