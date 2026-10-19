import SwiftUI

var keyLayout = "QWERTYUIOPASDFGHJKLZXCVBNM".map { String($0) }

let segmentWidth: CGFloat = 20
let segmentDefaultHeight: CGFloat = 30
let segmentRaisedHeight: CGFloat = 60

struct ContentView: View {
    @State var keyboardState: KeyboardState = .init(keys: keyLayout)

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(keyLayout.enumerated(), id: \.offset) { (_, key) in
                let isPressed = keyboardState.currentlyPressedKeys[key]?.isPressed ?? false

                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: segmentWidth,
                        height: isPressed ? segmentRaisedHeight : segmentDefaultHeight
                    )
                    .overlay(alignment: .bottom) {
                        Text(key)
                            .padding(.bottom, 5)
                    }
            }
        }
        .frame(height: segmentRaisedHeight, alignment: .bottom)
        .overlay {
            Path { path in
                let startingPoint = CGPoint(x: 0, y: segmentDefaultHeight)
                let endingPoint = CGPoint(x: segmentWidth * CGFloat(keyLayout.count), y: segmentDefaultHeight)
                path.move(to: startingPoint)
                var previous: CGPoint = startingPoint
                for (index, key) in keyLayout.enumerated() {
                    let isPressed = keyboardState.currentlyPressedKeys[key]?.isPressed ?? false
                    let coordinate = CGPoint(x: segmentWidth * (CGFloat(index) + 0.5), y: isPressed ? segmentRaisedHeight : segmentDefaultHeight)

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
                withAnimation(.interactiveSpring) {
                    keyboardState.update(forEvent: event)
                }
            }
        }
    }
}

struct KeyboardState: Hashable {
    struct KeyState: Hashable {
        var isPressed: Bool
        var lastChanged: Date
    }

    /// All keys and their current state
    var currentlyPressedKeys: [String: KeyState]

    init(keys: any Sequence<String>) {
        currentlyPressedKeys = .init(
            uniqueKeysWithValues: keys
                .map { ($0, KeyState(isPressed: false, lastChanged: .distantPast)) }
        )
    }

    mutating func update(forEvent event: KeyEventInfo) {
        guard currentlyPressedKeys[event.physicalKeyName] != nil else {
            print("No physical key registered: \(event.physicalKeyName)")
            return
        }

        currentlyPressedKeys[event.physicalKeyName] = .init(
            isPressed: event.phase == .down,
            lastChanged: .now
        )
    }
}
