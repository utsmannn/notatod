//
// Created by utsman on 08/03/21.
//

import Foundation
import SwiftUI

struct ShortcutView: View {

    var keys: [String]
    var body: some View {
        HStack {
            ForEach(0..<keys.count) { i in
                HStack(alignment: .center) {
                    Text(keys[i])
                            .frame(width: 20, height: 20)
                            .frame(alignment: .center)
                            .background(Color.gray.cornerRadius(2))
                    if i+1 != (keys.count) {
                        Text("+")
                    }
                }
            }
        }
    }
}