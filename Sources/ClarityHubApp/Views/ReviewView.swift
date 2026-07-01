import SwiftUI

struct ReviewView: View {
    @State private var wins = ""
    @State private var friction = ""
    @State private var nextFocus = ""

    var body: some View {
        ScreenScaffold(title: "Review", subtitle: "Close the loop before tomorrow starts.") {
            reviewField("Wins", text: $wins, prompt: "What moved forward?")
            reviewField("Friction", text: $friction, prompt: "What created drag?")
            reviewField("Next focus", text: $nextFocus, prompt: "What deserves the first block?")
        }
    }

    private func reviewField(_ title: String, text: Binding<String>, prompt: String) -> some View {
        SectionPanel(title: title) {
            TextField(prompt, text: text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }
}

