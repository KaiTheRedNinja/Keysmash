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

@Observable
class GameManager {
    let keyLayout: [String]
    var currentlyPressedKeys: [String: KeyState]
    var keyHeight: [String: CGFloat]

    var boats: [Boat]

    var prevTick: Date?

    struct KeyState: Hashable {
        var isPressed: Bool
        var lastChanged: Date
    }

    struct Boat: Identifiable, Hashable {
        var id: UUID = .init()
        // Coordinate of the bottom-center of the boat, offset from the bottom-left
        var coordinate: CGPoint
        // The angle of the boat, in clockwise degrees from flat
        var angle: Angle
        // The horizontal velocity of the boat (vertical position is determined by water level)
        var velocity: CGFloat
        // The maximum acceleration of the boat
        let acceleration: CGFloat = 50 // full acceleration is 100 units/s^2
        // The speed decay of the boat, in m/s^2
        let decay: CGFloat = 5
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
        self.boats = [
            .init(
                coordinate: .init(x: 0, y: segmentDefaultHeight),
                angle: .zero,
                velocity: 30 // 30 points per second
            )
        ]
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
        defer { self.prevTick = date }

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

        // skip first tick for velocity calculations
        guard let prevTick else { return }
        let dt = date.timeIntervalSince(prevTick)

        // calculate velocity of boat
        for (arrayIndex, boat) in boats.enumerated() {
            var newBoat = boat

            // if the boat is within the wave area, update its velocity and angle accordingly
            let index = Int((boat.coordinate.x + 0.5) / segmentWidth)
            if 0 <= index, index <= keyLayout.count { // index is within the key layout
                // 0 = to the left of the leftmost key
                // keyLayout.count = to the right of the rightmost key

                let lhsHeight = if index > 0 {
                    keyHeight[keyLayout[index-1]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }
                let rhsHeight = if index < keyLayout.count {
                    keyHeight[keyLayout[index]] ?? segmentDefaultHeight
                } else { segmentDefaultHeight }

                let opp = rhsHeight - lhsHeight // height diff
                let gradient = opp / segmentWidth

                newBoat.angle = .radians(-atan(gradient))
                newBoat.velocity -= newBoat.acceleration * opp / sqrt(segmentWidth*segmentWidth + opp*opp) // opp / hyp
            } else {
                // collision detection - it went too far to either side, make it bounce with 50% decay in velocity and also return it
                newBoat.velocity *= -0.5
                newBoat.coordinate.x = max(0, min(newBoat.coordinate.x, segmentWidth * CGFloat(keyLayout.count)))

                newBoat.angle = .zero
            }
            newBoat.velocity -= newBoat.decay * dt

            newBoat.coordinate.x += newBoat.velocity * dt

            boats[arrayIndex] = newBoat
        }
    }
}
