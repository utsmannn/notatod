//
// Created by utsman on 05/03/21.
//

import Foundation
import SwiftUI

func log(_ object: Any) {
    let date = Date()
    let tag = "\(date) | NOTATOD: "
    #if DEBUG
    print("\(tag)\(object)")
    #endif
}

extension NSApplication {

    var AppName: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    var AppVersionName: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var AppVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}