//
// Created by utsman on 04/03/21.
//

import Foundation
import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    private let featureMessage = "If you are going to participate as tester of this feature, please send me an email or contact me on github and tell me your gmail address"
    private let email = "mailto:utsmannn@gmail.com"
    private let github = "https://github.com/utsmannn"

    var body: some View {
        HStack {
            /*if signInViewModel.isGoogleAuthEnable {
                VStack {
                    Image("Gdrive")
                            .resizable()
                            .frame(width: 100, height: 70)
                    logonLeftView(logonStatus: signInViewModel.logonStatus)
                }
                logonRightView(logonStatus: signInViewModel.logonStatus)
            } else {
                VStack {
                    Image("Gdrive")
                            .resizable()
                            .frame(width: 100, height: 70)
                    Divider()
                    Text("Google Drive feature not yet available")
                }
            }*/
            VStack {
                Image("Gdrive")
                        .resizable()
                        .frame(width: 100, height: 70)
                Divider()
                Text("Google Drive feature not yet available")
            }

        }.padding().onAppear {
            //log("sign in available ----> \(signInViewModel.isGoogleAuthEnable)")
        }
    }

    /*private func logonLeftView(logonStatus: LogonStatus) -> AnyView {
        switch signInViewModel.logonStatus {
        case .sign_in, .sign_in_success:
            return AnyView(VStack {
                Text("You have logged in")
                        .font(.footnote)
                Button(action: {
                    signInViewModel.signIn()
                }, label: {
                    Text("Change account")
                })
            })
        case .sign_in_failed:
            return AnyView(VStack {
                Text("Sign in error")
                Button(action: {
                    signInViewModel.signIn()
                }, label: {
                    Text("Sign in with Google")
                })
            })
        default:
            return AnyView(HStack {
                VStack(alignment: .leading) {
                    Spacer()
                    Button(action: {
                        signInViewModel.signIn()
                    }, label: {
                        Text("Sign in with Google")
                    })
                    Text("Sync and save your notes on google drive")
                    Spacer()
                    Text("""
                         Attention! 
                         This feature currently on testing!
                         """)
                            .bold()
                    Spacer()
                }
                Divider().padding()
                VStack(alignment: .leading) {
                    Text(featureMessage)
                    Button(action: {
                        email.clickUrl()
                    }, label: {
                        Text("Send me email")
                    })
                    Button(action: {
                        github.clickUrl()
                    }, label: {
                        Text("Text me on github")
                    })
                }
            })
        }
    }

    private func logonRightView(logonStatus: LogonStatus) -> AnyView {
        switch signInViewModel.logonStatus {
        case .sign_in, .sign_in_success:
            return AnyView(HStack {
                Divider().padding()
                VStack(alignment: .leading) {
                    Text("Your Drive authorized by: ")
                    Text(signInViewModel.profile!.name)
                    Text(signInViewModel.profile!.email)
                    Spacer()

                    let dateApi = signInViewModel.fileInfo?.modifiedDate.replacingOccurrences(of: "Z", with: "")
                    if dateApi == nil {
                        EmptyView()
                    } else {
                        let dateString = dateApi?.dropLast(7).string.replacingOccurrences(of: "T", with: " ")
                        let date = dateString?.dateNow?.asStringFormat()
                        Text("""
                             Last edit: 
                             \(date!)
                             """)
                                .font(.footnote)
                        Text("""
                             File name on your Google Drive: 
                             notatod_content.csv
                             """)
                                .font(.footnote)
                    }
                }.padding(.vertical)

            })
        default:
            return AnyView(EmptyView())
        }
    }*/
}
