//
//  AppDelegate.swift
//  notatod
//
//  Created by utsman on 03/03/21.
//
//

import Cocoa
import SwiftUI
import KeyboardShortcuts

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    let userDefaultController = UserDefaultController()
    let driveController = DriveController()

    var signInViewModel: GoogleSignInViewModel!
    var mainViewModel: MainViewModel!

    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var preferencesWindow: NSWindow!

    typealias UserNotification = NSUserNotification
    typealias UserNotificationCenter = NSUserNotificationCenter
    let UserNotificationDefaultSoundName = NSUserNotificationDefaultSoundName


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // uncomment for see UserDefaultData
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains(UserDefaultController.TAG) {
                log("\n\(key) : \n\(value) \n")
            }
        }

        signInViewModel = GoogleSignInViewModel(userDefaultController: userDefaultController, driveController: driveController)
        driveController.accessToken = signInViewModel.getAccessToken()

        mainViewModel = MainViewModel(driveController: driveController, userDefaultController: userDefaultController)
        if signInViewModel.profile != nil {
            signInViewModel.statusAuth = .sign_in
        }

        mainViewModel.hasLogon = signInViewModel.profile != nil
        getFileInDrive()
        let contentView = ContentView()
                .environmentObject(mainViewModel)

        UserNotificationCenter.default.delegate = self

        statusBarItem = NSStatusBar.system.statusItem(withLength: 28)

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 800, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        self.popover.appearance = userDefaultController.theme()

        //statusBarItem.button?.image = NSImage(named:NSImage.Name("AppIcon"))
        if let button = statusBarItem.button {
            button.image = #imageLiteral(resourceName: "AppIcon")
            button.image?.size = NSSize(width: 22, height: 22)
            button.action = #selector(togglePopover(_:))
        }

        //setupKeyboardShortcut()
        NSApp.activate(ignoringOtherApps: true)

        /*NSApplication.shared.windows.forEach { window in
            window.appearance = NSAppearance(named: .aqua)
        }*/
    }

    func getFileInDrive() {
        mainViewModel.getFileInDrive { success in
            log("drive -> \(success)")
            if !success {
                if self.userDefaultController.notes().isEmpty {
                    let list = ConstantData.startingEntity()
                    self.mainViewModel.setupInitializer(entities: list)
                    self.mainViewModel.setSelectionId(selectionId: self.mainViewModel.notes[0].id)
                } else {
                    self.mainViewModel.notes = self.userDefaultController.notes()
                    self.mainViewModel.setSelectionId(selectionId: self.mainViewModel.notes[0].id)
                }
            } else {
                self.signInViewModel.getFileInfoInDrive()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        userDefaultController.saveNotes(notes: mainViewModel.notes)
        log("quit...")
    }

    func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyUp(for: .newNote) {
            self.userDefaultController.saveNotes(notes: self.mainViewModel.notes)
            self.mainViewModel.addNewNote()
        }
        KeyboardShortcuts.onKeyUp(for: .saveNote) {
            if self.mainViewModel.hasLogon == true {
                self.mainViewModel.uploadToDrive { b in
                    var message = ""
                    if b {
                        message = "Upload to Drive success"
                    } else {
                        message = "Upload to Drive failed!"
                    }
                    self.showNotification(message: message)
                }
            }
            self.mainViewModel.userDefaultController.saveNotes(notes: self.mainViewModel.notes)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let isGoogleUrl = signInViewModel.expectGoogleUserUrl(url: urls)
        if isGoogleUrl.0 {
            signInViewModel.getTokenResponse(using: isGoogleUrl.1!) { result in
                switch result {
                case .success(let success):
                    log("token is --> \(success.accessToken)")
                    self.driveController.accessToken = success.accessToken
                    self.showNotification(message: "Google account connected")
                    self.signInViewModel.requestProfile(idToken: success.idToken)
                    self.mainViewModel.hasLogon = self.signInViewModel.profile != nil
                    self.getFileInDrive()
                case .failure(let error):
                    log("reason --> \(error.localizedDescription)")
                    self.showNotification(message: "Google account failed")
                }

                log(self.signInViewModel.statusAuth)
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func showNotification(message: String) {
        log("show notification...")
        let notification: UserNotification = UserNotification()
        notification.title = "Account"
        notification.informativeText = message
        notification.soundName = UserNotificationDefaultSoundName
        UserNotificationCenter.default.deliver(notification)
        NSApplication.shared.unhide(self)
    }

    func openPreferencesWindow(tabDefault: Tab) {
        userDefaultController.saveNotes(notes: mainViewModel.notes)
        signInViewModel.tabDefault = .constant(tabDefault)

        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
                    .environmentObject(signInViewModel)

            let windowView = NSHostingController(rootView: preferencesView)
            preferencesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                    backing: .buffered, defer: false)
            preferencesWindow.title = "Preferences"
            preferencesWindow.center()
            preferencesWindow.setFrameAutosaveName("Preferences")
            preferencesWindow.isReleasedWhenClosed = false
            preferencesWindow.contentView = windowView.view
            preferencesWindow.appearance = userDefaultController.theme()
        }

        preferencesWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func changeThemeNow() {
        popover.appearance = userDefaultController.theme()
        preferencesWindow.appearance = userDefaultController.theme()
    }

}
