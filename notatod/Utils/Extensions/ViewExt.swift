//
// Created by utsman on 04/03/21.
//

import Foundation
import SwiftUI
import Combine

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            backgroundColor = .clear //<<here clear
            drawsBackground = true
        }
    }
}