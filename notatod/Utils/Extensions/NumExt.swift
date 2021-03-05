//
// Created by utsman on 04/03/21.
//

import Foundation
import SwiftUI

extension Double {

    mutating func asBinding(onChanged: @escaping (Double) -> ()) -> Binding<Double> {
        var mutating = self
        let binding = Binding<Double>(get: { () -> Double in
            mutating
        }, set: { s in
            mutating = s
            onChanged(s)
        })
        return binding
    }
}