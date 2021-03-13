//
// Created by utsman on 05/03/21.
//

import Foundation
import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        HStack {
            /*if signInViewModel.isUpdateAvailable {
                VStack(alignment: .leading) {
                    Text("Update available")
                            .bold()
                    Divider()
                    Text("Version \(signInViewModel.version?.versionName ?? "Unknown") (\(signInViewModel.version?.versionCode ?? 0))")
                    Text(signInViewModel.version?.changelogString ?? "")
                            .padding(.leading)
                    Spacer()
                    Button(action: {
                        let downloadPageUrlString = signInViewModel.version?.downloadPage ?? "https://github.com/utsmannn"
                        downloadPageUrlString.clickUrl()
                    }, label: {
                        Text("Update now")
                    })
                }.padding()
                Spacer()
            } else {
                Text("No update available")
            }*/
            Text("No update available")
        }.padding()
    }
}