//
// Created by utsman on 04/03/21.
//

import Foundation
import SwiftUI

struct GeneralView: View {
    @EnvironmentObject var signInViewModel: GoogleSignInViewModel

    let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate

    enum TaggedTheme: String {
        case dark = "dark"
        case light = "light"
        case auto = "auto"
    }

    @State var theme = TaggedTheme.auto
    @State var isLaunchAtLogin = false

    private let shortcutOpen = ["⌘", "⌥", "⌃", "O"]
    private let shortcutNewNote = ["⌘", "⌥", "⌃", "N"]
    private let shortcutSaveNote = ["⌘", "⌥", "⌃", "S"]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Picker(selection: $theme, label: Text("Theme application: ")) {
                        Text("Dark").tag(TaggedTheme.dark)
                        Text("Light").tag(TaggedTheme.light)
                        Text("Auto").tag(TaggedTheme.auto)
                    }.frame(maxWidth: 400).onReceive([theme].publisher.first()) { (v: TaggedTheme) in
                        log("changed -> \(v)")
                        let nsAppearance = taggedToNSAppearance(taggedTheme: v)
                        signInViewModel.userDefaultController.setTheme(name: nsAppearance?.name)
                        appDelegate?.changeThemeNow()
                    }

                    Divider()

                    Toggle("Launch at login", isOn: $isLaunchAtLogin)
                            .frame(alignment: .leading).frame(alignment: .top)
                            .disabled(true)

                    Button(action: {
                        NSApplication.shared.terminate(self)
                    }, label: {
                        Text("Exit application")
                    }).padding(.top)
                    Spacer()
                    Divider()
                }
                Spacer().frame(width: 20)
                ZStack {
                    Image(getImageTheme(taggedTheme: theme))
                            .resizable()
                            .cornerRadius(8).padding(1)
                }.frame(width: 120, height: 120)
                        .background((theme == TaggedTheme.dark ? Color.white : Color.gray).cornerRadius(8))
            }

            VStack(alignment: .leading) {
                Text("Shortcut:")
                        .bold()
                        .padding(.bottom, 7)
                HStack {
                    Text("Open/toggle note")
                            .frame(width: 120, alignment: .leading)
                    Text(" : ")
                    ShortcutView(keys: shortcutOpen)
                }
                HStack {
                    Text("New note")
                            .frame(width: 120, alignment: .leading)
                    Text(" : ")
                    ShortcutView(keys: shortcutNewNote)
                }.padding(.vertical, 3)
                HStack {
                    Text("Save notes")
                            .frame(width: 120, alignment: .leading)
                    Text(" : ")
                    ShortcutView(keys: shortcutSaveNote)
                }
            }

            Spacer()
            Spacer()

            Text(signInViewModel.versionName())
                    .font(.footnote)
                    .frame(alignment: .trailing)

        }
                .padding()
                .onAppear {
                    theme = getTaggedFromAppearance(appearance: signInViewModel.userDefaultController.theme())
                }
    }

    private func getImageTheme(taggedTheme: TaggedTheme) -> String {
        switch (taggedTheme) {
        case .dark:
            return "ImageDark"
        case .light:
            return "ImageLight"
        case .auto:
            return "ImageAuto"
        }
    }

    private func getTaggedFromAppearance(appearance: NSAppearance?) -> TaggedTheme {
        guard let appearanceName = appearance?.name else {
            return .auto
        }

        switch appearanceName {
        case .aqua:
            return TaggedTheme.light
        case .darkAqua:
            return TaggedTheme.dark
        default:
            return TaggedTheme.auto
        }
    }

    private func taggedToNSAppearance(taggedTheme: TaggedTheme) -> NSAppearance? {
        switch taggedTheme {
        case .auto:
            return nil
        case .dark:
            return NSAppearance(named: .darkAqua)
        case .light:
            return NSAppearance(named: .aqua)
        }
    }
}
