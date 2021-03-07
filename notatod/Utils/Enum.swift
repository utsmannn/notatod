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
}

enum Tab: Hashable {
    case general
    case account
    case update
    case about
}