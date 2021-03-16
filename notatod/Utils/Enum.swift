//
// Created by utsman on 04/03/21.
//

import Foundation
import SwiftUI

enum Error: Swift.Error {
    case code_not_found_in_redirect_URL
    case network_error(Swift.Error)
    case invalid_response
    case decoding_error(Swift.Error)
    case invalid_credential
    case not_found
}

enum AuthTypeUrl<URL> {
    case google(URL)
    case dropbox(URL)
    case none
}

enum AuthType {
    case google
    case dropbox
    case disable
}

extension AuthType {
    func enumAPI() -> String {
        switch self {
        case .google:
            return "GOOGLE_DRIVE"
        case .dropbox:
            return "DROPBOX"
        case .disable:
            return ""
        }
    }
}

enum Method: String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
}

enum ContentType: String {
    case application_form_urlencoded = "application/x-www-form-urlencoded"
    case application_json = "application/json"
    case multipart_related_boundary = "multipart/related; boundary=foo_bar_baz"
    case application_octet_stream = "application/octet-stream"
    case text_plain = "text/plain"
}

enum Tab: Hashable {
    case general
    case account
    case update
    case about
}