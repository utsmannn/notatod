//
// Created by utsman on 03/03/21.
//

import Foundation

extension Date {

    func asStringFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E HH:mm, d MMM y"
        return formatter.string(from: self)
    }

    func asMillisecond() -> Int {
        let timeInterval = timeIntervalSince1970
        return Int(timeInterval)
    }
}