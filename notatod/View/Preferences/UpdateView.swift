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

            if signInViewModel.isUpdateAvailable {

                VStack(alignment: .leading) {
                    Text("Update available")
                            .bold()
                    Spacer()
                    Text("Version \(signInViewModel.version?.versionName ?? "Unknown") (\(signInViewModel.version?.versionCode ?? 0))")
                    HStack {
                        Spacer()
                        Text(signInViewModel.version?.changelogString ?? "")
                        Spacer()
                    }
                    Spacer()
                    Spacer()
                    Button(action: {
                        let downloadPageUrlString = signInViewModel.version?.downloadPage ?? "https://github.com/utsmannn"
                        let downloadPageUrl = URL(string: downloadPageUrlString)
                        let config = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.open(downloadPageUrl!, configuration: config) { application, error in
                            log("opening..")
                        }
                    }, label: {
                        Text("Update now")
                    })
                }.padding()


            } else {
                Text("No update available")
                        .frame(alignment: .topLeading)
            }
            Spacer()
        }.padding()
    }

    private func versionName() -> String {
        let versionName = NSApplication.shared.AppVersionName ?? "Unknown"
        let versionCode = NSApplication.shared.AppVersion ?? "Unknown"
        return "Version \(versionName) (\(versionCode))"
    }
}