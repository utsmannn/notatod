//
// Created by utsman on 03/03/21.
//

import Foundation

class EditorViewModel : ObservableObject, Equatable {
    static func ==(lhs: EditorViewModel, rhs: EditorViewModel) -> Bool {
        lhs.initialText == rhs.initialText
    }

    @Published var initialText: String = "init"
}