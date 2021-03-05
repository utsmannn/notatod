//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI
import Combine
import RxSwift
import RxCocoa

struct ImageButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .foregroundColor(configuration.isPressed ? Color.gray : Color.white)
    }
}

struct EditorView: View {
    @ObservedObject var mainViewModel: MainViewModel
    @State var entities: NoteEntity

    let appDelegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
    @State var fontSize: Double = 16

    var body: some View {
        let bodyBinding = entities.body.asBinding { s in
            entities.body = s
            mainViewModel.userDefaultController.saveNotes(notes: mainViewModel.notes)
        }

        let titleBinding = entities.title.asBinding { s in
            entities.title = s
            mainViewModel.setSelectionId(selectionId: entities.id)
            mainViewModel.userDefaultController.saveNotes(notes: mainViewModel.notes)
        }

        let fontBinding = fontSize.asBinding { v in
            fontSize = v
            mainViewModel.fontSize = v
        }

        return VStack(spacing: 0) {
            VStack(spacing: 0) {
                TextEditor(text: titleBinding)
                        .font(.system(size: CGFloat(mainViewModel.fontSize * 2)))
                        .frame(height: CGFloat(mainViewModel.fontSize * 4))
                        .frame(alignment: .top)

                TextEditor(text: bodyBinding)
                        .font(.system(size: CGFloat(mainViewModel.fontSize * 1.2)))
                        .frame(alignment: .top)

            }.padding()

            HStack {
                Button(action: {
                    mainViewModel.addNewNote()
                }, label: {
                    Image(systemName: "doc.text")
                            .resizable()
                            .frame(width: 16, height: 20)
                }).frame(alignment: .leading)
                        .buttonStyle(ImageButtonStyle())
                        .tooltip("New note (cmd+n)")

                Button(action: {
                    appDelegate?.openPreferencesWindow(tabDefault: .account)
                }, label: {
                    Image(systemName: mainViewModel.hasLogon == true ? "link.icloud.fill" : "xmark.icloud.fill")
                            .resizable()
                            .frame(width: 25, height: 18)
                }).frame(alignment: .leading).padding([.trailing, .leading])
                        .buttonStyle(ImageButtonStyle())
                        .tooltip(mainViewModel.hasLogon == true ? "Account connected" : "Account not connected")

                Button(action: {
                    appDelegate?.openPreferencesWindow(tabDefault: .general)
                }, label: {
                    Image(systemName: "slider.vertical.3")
                            .resizable()
                            .frame(width: 18, height: 20)
                }).frame(alignment: .leading)
                        .buttonStyle(ImageButtonStyle())
                        .tooltip("Open preferences")

                Spacer().frame(width: 20)
                Divider().frame(height: 22)
                Spacer().frame(width: 20)
                HStack(alignment: .center) {
                    Text("A+")
                    Slider(value: fontBinding, in: 1...50, step: 5)
                    Text("A-")
                }
                Spacer().frame(width: 20)
                if mainViewModel.hasLogon == true {
                    Divider().frame(height: 22)
                    Button(action: {
                        mainViewModel.uploadToDrive { b in
                            var message = ""
                            if b {
                                message = "Upload to Drive success"
                            } else {
                                message = "Upload to Drive failed!"
                            }
                            appDelegate?.showNotification(message: message)
                        }
                    }, label: {
                        Image(systemName: "icloud.and.arrow.up.fill")
                                .resizable()
                                .frame(width: 25, height: 20)
                    }).frame(alignment: .leading)
                            .buttonStyle(ImageButtonStyle())
                            .tooltip("Upload to drive")
                }

            }.frame(alignment: .bottomLeading).padding().onAppear {
                fontSize = mainViewModel.fontSize
            }
        }
    }
}