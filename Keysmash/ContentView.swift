import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Press any key")
                .font(.title)

            Text("Key events are printed to the console.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            KeyCaptureView { event in
                let phase = event.phase == .down ? "Down" : "Up"

                print(
                    """
                    \(phase): keyCode=\(event.keyCode),
                    modifiers=\(event.modifiers),
                    repeat=\(event.isRepeat),
                    decoded=\(event.physicalKeyName)
                    """
                )
            }
        }
    }
}
