//
//  ContentView.swift
//  notatod
//
//  Created by utsman on 03/03/21.
//
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    @State var hasLogon = false

    var body: some View {
        NavigationView {
            VStack {
                List(mainViewModel.notes) { (note: NoteEntity) in
                    NavigationLink(destination: EditorView(
                            mainViewModel: mainViewModel,
                            entities: note
                    ), tag: note.id, selection: $mainViewModel.selection) {
                        VStack(alignment: .leading) {
                            Spacer()
                            Text(note.title)
                            Spacer().frame(height: 2)
                            Text(note.date.asStringFormat())
                                    .font(.footnote)
                            Spacer()
                        }
                    }.contextMenu {
                        Button(action: {
                            mainViewModel.removeNote(noteId: note.id)
                        }) {
                            Text("Delete")
                        }
                    }
                }.listStyle(SidebarListStyle())
            }.frame(minWidth: 200).onAppear {
                self.hasLogon = mainViewModel.hasLogon ?? false
            }
        }
    }
}
