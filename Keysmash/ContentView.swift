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
                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: segmentWidth,
                        height: manager.keyHeight[key] ?? 0
                    )
                    .overlay(alignment: .bottom) {
                        Text(key)
                            .padding(.bottom, 5)
                    }
            }
        }
        .frame(height: segmentRaisedHeight, alignment: .bottom)
        .overlay(alignment: .bottomLeading) {
            ForEach(manager.boats) { boat in
                UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 10, bottomTrailing: 10))
                    .fill(Color.brown)
                    .frame(width: 100, height: 20)
                    .rotationEffect(boat.angle, anchor: .bottom)
                    .offset(x: -50)
                    .offset(x: boat.coordinate.x, y: -boat.coordinate.y)
            }
        }
        .overlay {
            Path { path in
                let startingPoint = CGPoint(x: 0, y: segmentDefaultHeight)
                let endingPoint = CGPoint(x: segmentWidth * CGFloat(manager.keyLayout.count), y: segmentDefaultHeight)
                path.move(to: startingPoint)
                var previous: CGPoint = startingPoint
                for (index, key) in manager.keyLayout.enumerated() {
                    let coordinate = CGPoint(x: segmentWidth * (CGFloat(index) + 0.5), y: manager.keyHeight[key] ?? 0)

                    // control is midpoint of previous and coordinate
                    let control1 = CGPoint(x: (previous.x + coordinate.x)/2, y: previous.y)
                    let control2 = CGPoint(x: (previous.x + coordinate.x)/2, y: coordinate.y)
                    path.addCurve(to: coordinate, control1: control1, control2: control2)
                    previous = coordinate
                }
                path.addLine(to: endingPoint)
            }
            .scale(x: 1, y: -1) // vertically flip
            .stroke(Color.red, lineWidth: 4)
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

