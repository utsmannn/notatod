//
// Created by utsman on 03/03/21.
//

import Foundation

extension Data {
    func asString() -> String {
        String(data: self, encoding: .utf8)!
    }

    func decodeData<T: Codable>() throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: self)
    }
}