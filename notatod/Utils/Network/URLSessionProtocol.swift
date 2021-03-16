//
// Created by utsman on 03/03/21.
//

import Foundation

public protocol URLSessionProtocol {
    func dataTask(
            with request: URLRequest,
            completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void
    ) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}