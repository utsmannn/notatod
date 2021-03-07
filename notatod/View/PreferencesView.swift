//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var signInViewModel: GoogleSignInViewModel
    @State var tab = Tab.general

    var body: some View {
        TabView(selection: $tab) {
            GeneralView()
                    .tabItem {
                        Text("General")
                    }.tag(Tab.general)
            AccountView()
                    .tabItem {
                        Text("Account")
                    }.tag(Tab.account)
            UpdateView()
                    .tabItem {
                        Text("Update")
                    }.tag(Tab.update)
            AboutView()
                    .tabItem {
                        Text("About")
                    }.tag(Tab.about)
        }.padding().frame(height: 340)
    }
}