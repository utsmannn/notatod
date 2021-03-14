//
// Created by utsman on 05/03/21.
//

import Foundation
import SwiftUI

struct UpdateView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    var body: some View {
        HStack {
            if mainViewModel.isUpdateAvailable {
                VStack(alignment: .leading) {
                    Text("Update available")
                            .bold()
                    Divider()
                    Text("Version \(mainViewModel.version?.versionName ?? "Unknown") (\(mainViewModel.version?.versionCode ?? 0))")
                    Text(mainViewModel.version?.changelogString ?? "")
                            .padding(.leading)
                    Spacer()
                    Button(action: {
                        let downloadPageUrlString = mainViewModel.version?.downloadPage ?? "https://github.com/utsmannn"
                        downloadPageUrlString.clickUrl()
                    }, label: {
                        Text("Update now")
                    })
                }.padding()
                Spacer()
            } else {
                Text("No update available")
            }
        }.padding()
    }
}