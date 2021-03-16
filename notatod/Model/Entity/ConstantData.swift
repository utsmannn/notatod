//
// Created by utsman on 03/03/21.
//

import Foundation

class ConstantData {
    static func generateRandomNote() -> NoteEntity {
        let notes = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
            "Sed eu fermentum tellus.",
            "Quisque ut malesuada leo. Vivamus semper mauris nec aliquam posuere. ",
            "Curabitur nec dapibus diam, ut auctor tortor.",
            "Integer eu euismod sem, ut tincidunt sapien.",
            "Class aptent taciti sociosqu ad litora torquent per conubia nostra",
            "Ut lobortis lectus in nisl consectetur eleifend.",
            "Nullam lobortis metus aliquam purus vehicula posuere.",
            "Ut ut sem ut purus laoreet sagittis non vel augue.",
            "nc ut felis nisl. Mauris sem nisi, hendrerit sit amet ligula sed, iaculis porta erat. Duis id convallis mauris, vitae porttitor magna."
        ]

        let shuffled = notes.shuffled()
        let single = shuffled.choose(1).first ?? "okeeee"
        let id = "id_of_\(single[0...13])"
        let title = "\(single[0...10])"
        let date = Date()

        return NoteEntity(id: id, title: title, body: single, date: date)
    }

    static func entities() -> [NoteEntity] {
        let range = 1...30
        let lists = range.map { i -> NoteEntity in
            ConstantData.generateRandomNote()
        }

        return lists
    }

    static func startingEntity() -> [NoteEntity] {
        let starting = NoteEntity(
                id: UUID().uuidString,
                title: "Sample note",
                body: "This is sample note",
                date: Date()
        )
        return [starting]
    }

}