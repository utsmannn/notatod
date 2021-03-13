//
// Created by utsman on 08/03/21.
//

import Foundation
import SwiftUI

struct AboutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    private let developerName = "Muhammad Utsman"
    private let email = "mailto:utsmannn@gmail.com"
    private let mainPage = "https://github.com/utsmannn/notatod"
    private let kofiPage = "https://ko-fi.com/utsmannn"
    private let saweria = "https://saweria.co/utsmannn"

    var body: some View {
        HStack {
            VStack {
                Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 100, height: 100)

                Text(NSApplication.shared.AppName ?? "Notatod")
                        .bold()
                /*Text(signInViewModel.versionName())
                        .font(.footnote)*/
            }.padding()
            Divider().padding(.trailing).padding(.vertical)
            VStack(alignment: .leading) {
                Text("Develop with ❤️ by \(developerName)")
                Button(action: {
                    email.clickUrl()
                }, label: {
                    Text("utsmannn@gmail.com")
                }).buttonStyle(PlainButtonStyle())

                Button(action: {
                    mainPage.clickUrl()
                }, label: {
                    Text(mainPage)
                }).buttonStyle(PlainButtonStyle())
                Spacer()
                Text("Buy me coffee on")
                Divider()
                VStack(alignment: .leading) {
                    Button(action: {
                        kofiPage.clickUrl()
                    }, label: {
                        Text(kofiPage)
                    }).buttonStyle(PlainButtonStyle())

                    Button(action: {
                        saweria.clickUrl()
                    }, label: {
                        Text(saweria)
                    }).buttonStyle(PlainButtonStyle())
                }.padding(.leading)
                Spacer()
            }.padding(.vertical)
            Spacer()
            Spacer()
        }
    }
}
