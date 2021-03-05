//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    mutating func asBinding(onChanged: @escaping (String) -> ()) -> Binding<String> {
        var mutating = self
        let binding = Binding<String>(get: { () -> String in
            mutating
        }, set: { s in
            mutating = s
            onChanged(s)
        })
        return binding
    }

    /*var iso8601withFractionalSeconds: Date? {
        Formatter.iso8601withFractionalSeconds.date(from: self)
    }*/
     var dateNow: Date? {
         let formatter = DateFormatter()
         formatter.timeZone = TimeZone(abbreviation: "GMT")
         formatter.dateFormat = "yyyy-MM-dd HH:mm"
         return formatter.date(from: self)
     }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
}