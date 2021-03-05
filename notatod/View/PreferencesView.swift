//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var signInViewModel: GoogleSignInViewModel

    var body: some View {
        TabView(selection: signInViewModel.tabDefault) {
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
        }.padding().frame(height: 240)
    }
}