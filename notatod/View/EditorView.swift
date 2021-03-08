//
// Created by utsman on 03/03/21.
//

import Foundation
import SwiftUI

struct ImageButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .foregroundColor(configuration.isPressed ? Color.gray : Color.white)
    }
}

struct EditorView: View {
    @Environment(\.colorScheme) var colorScheme
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
                TextEditorCatalina(text: titleBinding, font: .systemFont(ofSize: CGFloat(mainViewModel.fontSize * 2), weight: .bold))
                        .frame(height: CGFloat(mainViewModel.fontSize * 4))
                        .frame(alignment: .top)

                TextEditorCatalina(text: bodyBinding, font: .systemFont(ofSize: CGFloat(mainViewModel.fontSize * 1.2)))
                        .frame(alignment: .top)

            }.padding()

            HStack {
                Button(action: {
                    mainViewModel.addNewNote()
                }, label: {
                    Image("ControlAddDocument")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .colorMultiply(colorScheme == .dark ? Color.white : Color.black)

                }).frame(alignment: .leading)
                        .buttonStyle(ImageButtonStyle())
                        .tooltip("New note")

                Button(action: {
                    appDelegate?.openAccountWindow()
                }, label: {
                    Image(mainViewModel.hasLogon == true ? "ControlCloudOn" : "ControlCloudOf")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .colorMultiply(colorScheme == .dark ? Color.white : Color.black)

                }).frame(alignment: .leading).padding([.trailing, .leading])
                        .buttonStyle(ImageButtonStyle())
                        .tooltip(mainViewModel.hasLogon == true ? "Account connected" : "Account not connected")

                Button(action: {
                    appDelegate?.openPreferencesWindow()
                }, label: {
                    Image("ControlSettings")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .colorMultiply(colorScheme == .dark ? Color.white : Color.black)

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

                    Divider().frame(height: 22)
                    Button(action: {
                        appDelegate?.changeSize()
                    }, label: {
                        Image("ControlWindow")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .colorMultiply(colorScheme == .dark ? Color.white : Color.black)
                    }).frame(alignment: .leading)
                            .buttonStyle(ImageButtonStyle())
                            .tooltip("Change window size")
                }
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
                        Image("ControlSaveDrive")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .colorMultiply(colorScheme == .dark ? Color.white : Color.black)
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