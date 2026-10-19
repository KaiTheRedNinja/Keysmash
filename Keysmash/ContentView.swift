import SwiftUI
import Combine

let segmentWidth: CGFloat = 20
let segmentDefaultHeight: CGFloat = 30
let segmentRaisedHeight: CGFloat = 60

let activationTime: TimeInterval = 1 // takes 1s to build up fully
let deactivationTime: TimeInterval = 0.5 // takes 0.5s to dissipate

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
        .onReceive(gameTimer) { _ in
            manager.tick()
        }
    }
}

@Observable
class GameManager {
    let keyLayout: [String]
    var currentlyPressedKeys: [String: KeyState]
    var keyHeight: [String: CGFloat]

    struct KeyState: Hashable {
        var isPressed: Bool
        var lastChanged: Date
    }

    init(keysStr: String = "QWERTYUIOPASDFGHJKLZXCVBNM") {
        self.keyLayout = "QWERTYUIOPASDFGHJKLZXCVBNM".map { String($0) }
        precondition(keyLayout.count == Set(keyLayout).count, "Keysstr must not contain duplicates")

        self.currentlyPressedKeys = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, KeyState(isPressed: false, lastChanged: .distantPast)) }
        )
        self.keyHeight = .init(
            uniqueKeysWithValues: keyLayout
                .map { ($0, segmentDefaultHeight) }
        )
    }

    func update(forEvent event: KeyEventInfo) {
        guard let oldState = currentlyPressedKeys[event.physicalKeyName] else {
            print("No physical key registered: \(event.physicalKeyName)")
            return
        }
        guard !event.isRepeat, oldState.isPressed != (event.phase == .down) else {
            // key repeats are ignored
            // and so are repeats of the same keyup/keydown call
            return
        }

        currentlyPressedKeys[event.physicalKeyName] = .init(
            isPressed: event.phase == .down,
            lastChanged: .now
        )
    }

    func tick(date: Date = .now) {
        // recalculate all key heights
        keyHeight = currentlyPressedKeys.mapValues { state in
            if state.isPressed {
                // increasing decay curve
                segmentDefaultHeight + (segmentRaisedHeight - segmentDefaultHeight) * (
                    1 - exp(-3/activationTime * date.timeIntervalSince(state.lastChanged))
                )
            } else {
                // decreasing decay curve
                segmentDefaultHeight + (segmentRaisedHeight - segmentDefaultHeight) * (
                    exp(-3/deactivationTime * date.timeIntervalSince(state.lastChanged))
                )
            }
        }
    }
}
