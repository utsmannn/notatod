//
// Created by utsman on 05/03/21.
//

import Foundation
import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var signInViewModel: GoogleSignInViewModel
    var body: some View {
        HStack {
            VStack {
                Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 100, height: 100)

                Text(NSApplication.shared.AppName ?? "Notatod")
                        .bold()
                Text(versionName())
                        .font(.footnote)
            }.padding()
            Divider().padding()
            VStack(alignment: .leading) {
                Text("No update available")
                        .frame(alignment: .topLeading)
            }.padding()
            Spacer()
        }.padding()
    }

    private func versionName() -> String {
        let versionName = NSApplication.shared.AppVersionName ?? "Unknown"
        let versionCode = NSApplication.shared.AppVersion ?? "Unknown"
        return "Version \(versionName) (\(versionCode))"
    }
}