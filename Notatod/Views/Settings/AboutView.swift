import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 42))
            Text("Notatod")
                .font(.title2.weight(.semibold))
            Text("Menubar notes for macOS.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
