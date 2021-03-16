//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var tab = Tab.general

    var body: some View {
        TabView(selection: $tab) {
            GeneralView()
                    .tabItem {
                        Text("General")
                    }.tag(Tab.general)
                    .environmentObject(authViewModel)
            AccountView()
                    .tabItem {
                        Text("Account")
                    }.tag(Tab.account)
                    .environmentObject(authViewModel)
            UpdateView()
                    .tabItem {
                        Text("Update")
                    }.tag(Tab.update)
                    .environmentObject(mainViewModel)
            AboutView()
                    .tabItem {
                        Text("About")
                    }.tag(Tab.about)
                    .environmentObject(authViewModel)
        }
                .padding()
    }
}