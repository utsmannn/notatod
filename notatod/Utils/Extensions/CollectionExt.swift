//
// Created by utsman on 03/03/21.
//

import Foundation

extension Array {
    func randomItem() -> Element? {
        if isEmpty {
            return nil
        }
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else {
            return
        }
        remove(at: index)
    }

    func findIndex(object: Element) -> Int? {
        guard let index = firstIndex(of: object) else {
            return nil
        }
        return index
    }

    func find(object: Element) -> Element? {
        guard let index = findIndex(object: object) else { return nil }
        return self[index]
    }

}

extension Collection {
    func choose(_ n: Int) -> ArraySlice<Element> {
        shuffled().prefix(n)
    }
}