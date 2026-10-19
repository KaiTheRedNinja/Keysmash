import SwiftUI

var keyLayout = "QWERTYUIOPASDFGHJKLZXCVBNM".map { String($0) }

struct ContentView: View {
    @State var keyboardState: KeyboardState = .init(keys: keyLayout)

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(keyLayout.enumerated(), id: \.offset) { (_, key) in
                let isPressed = keyboardState.currentlyPressedKeys[key]?.isPressed ?? false

                Rectangle()
                    .fill(Color.blue)
                    .frame(
                        width: 20,
                        height: isPressed ? 100 : 30
                    )
                    .overlay(alignment: .bottom) {
                        Text(key)
                            .padding(.bottom, 5)
                    }
            }
        }
        .frame(height: 100, alignment: .bottom)
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
