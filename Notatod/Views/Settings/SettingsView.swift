import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SettingsService.self) private var settings
    @Environment(MenubarController.self) private var menubarController

    var body: some View {
        TabView(selection: Bindable(appState).selectedSettingsTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(AppState.SettingsTab.general)

            SyncSettingsView()
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(AppState.SettingsTab.sync)

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(AppState.SettingsTab.about)
        }
        .frame(width: 520, height: 420)
    }

    private var generalTab: some View {
        Form {
            Picker("Appearance", selection: Binding(
                get: { settings.appearance },
                set: {
                    settings.appearance = $0
                    appState.appearance = $0
                }
            )) {
                ForEach(AppState.Appearance.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Editor font size")
                        Text("Adjust the writing size and preview it live.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 16)

                    Text("\(Int(settings.editorFontSize)) pt")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }

                Slider(value: Binding(
                    get: { settings.editorFontSize },
                    set: {
                        settings.editorFontSize = $0
                        revealEditorForLivePreview()
                    }
                ), in: 12...24, step: 1)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Aa")
                            .font(.system(size: settings.editorFontSize + 8, weight: .semibold, design: .rounded))
                        Text("Preview your notes with this text size before editing.")
                            .font(.system(size: settings.editorFontSize, weight: .regular, design: .default))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.quinary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(.quaternary)
                    }
                }
            }

            Toggle("Launch at login", isOn: Binding(
                get: { settings.launchAtLogin },
                set: { settings.launchAtLogin = $0 }
            ))

            LabeledContent("Global hotkey") {
                Text("⌘⇧N")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func revealEditorForLivePreview() {
        menubarController.revealEditorPanel()
    }
}
