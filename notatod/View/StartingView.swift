//
// Created by utsman on 08/03/21.
//

import Foundation
import SwiftUI

struct StartingView: View {
    let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
    @EnvironmentObject var startingViewModel: StartingViewModel

    var body: some View {

        VStack {
            HStack {
                Image(nsImage: Bundle.main.image(forResource: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 60, height: 60)

                Text("notatod")
                        .bold()
                        .font(.title)
            }
            Text("Notes in your menu bar!")

            if startingViewModel.isReady {
                Button(action: {
                    NSApplication.shared.sendAction(#selector(appDelegate?.togglePopover(_:)), to: nil, from: nil)
                }, label: {
                    Text("Toggle note")
                })
                ShortcutView(keys: ["⌘", "⌥", "⌃", "O"])
            } else {
                if #available(OSX 11.0, *) {
                    ProgressView {
                        Text("Preparing...")
                    }
                } else {
                    Text("Preparing...").padding()
                }
            }

            Divider().padding(.top)
            Button(action: {
                appDelegate?.startingWindow.close()
            }, label: {
                Text("Close window")
            })
        }.padding().frame(width: 300)
    }
}