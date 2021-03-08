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
    let featureApiController = FeatureApiController()

    var signInViewModel: GoogleSignInViewModel!
    var mainViewModel: MainViewModel!

    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var preferencesWindow: NSWindow!
    var accountWindow: NSWindow!
    var startingWindow: NSWindow!

    typealias UserNotification = NSUserNotification
    typealias UserNotificationCenter = NSUserNotificationCenter
    let UserNotificationDefaultSoundName = NSUserNotificationDefaultSoundName


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // uncomment for see UserDefaultData
        openStartingWindow()
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains(UserDefaultController.TAG) {
                log("\n\(key) : \n\(value) \n")
            }
        }

        signInViewModel = GoogleSignInViewModel(
                userDefaultController: userDefaultController,
                driveController: driveController,
                featureApiController: featureApiController
        )

        driveController.accessToken = signInViewModel.getAccessToken()
        mainViewModel = MainViewModel(driveController: driveController, userDefaultController: userDefaultController)
        if signInViewModel.profile != nil {
            signInViewModel.logonStatus = .sign_in
        }

        mainViewModel.hasLogon = signInViewModel.profile != nil
        getFileInDrive()
        let contentView = ContentView()
                .environmentObject(mainViewModel)

        UserNotificationCenter.default.delegate = self
        statusBarItem = NSStatusBar.system.statusItem(withLength: 28)

        let popover = NSPopover()

        if userDefaultController.popoverWindowSize() == 2 {
            popover.contentSize = NSSize(width: 1000, height: 600)
        } else {
            popover.contentSize = NSSize(width: 800, height: 400)
        }

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        self.popover.appearance = userDefaultController.theme()

        if let button = statusBarItem.button {
            button.image = #imageLiteral(resourceName: "AppIcon")
            button.image?.size = NSSize(width: 22, height: 22)
            button.action = #selector(togglePopover(_:))
        }

        NSApp.activate(ignoringOtherApps: true)

        checkGoogleAuthEnable()
        checkUpdateAvailable()
        setupKeyboardShortcut()
    }

    func checkUpdateAvailable() {
        featureApiController.checkUpdateAvailable { os in
            let isUpdateAvailable = NSApplication.shared.AppVersionInt! < os.versionCode
            self.signInViewModel.version = os
            self.signInViewModel.isUpdateAvailable = isUpdateAvailable
        }
    }

    func checkGoogleAuthEnable() {
        featureApiController.isGoogleAuthEnable { b in
            if !b {
                self.userDefaultController.clearDriveData()
            }
            self.signInViewModel.isGoogleAuthEnable = b
        }
    }

    func getFileInDrive() {
        mainViewModel.getFileInDrive(onSuccess: { success in
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
        }, onError: { error in
            self.mainViewModel.notes = self.userDefaultController.notes()
            self.mainViewModel.setSelectionId(selectionId: self.mainViewModel.notes[0].id)

            switch error {
            case .invalid_credential:
                return log("Error credential")
            default:
                return
            }
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        userDefaultController.saveNotes(notes: mainViewModel.notes)
        log("quit...")
    }

    func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyUp(for: .openNote) {
            self.togglePopover(nil)
        }
        KeyboardShortcuts.onKeyUp(for: .newNote) {
            self.mainViewModel.addNewNote()
            self.togglePopover(nil)
        }
        KeyboardShortcuts.onKeyUp(for: .saveNote) {
            self.mainViewModel.userDefaultController.saveNotes(notes: self.mainViewModel.notes)

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
            } else  {
                self.showNotification(message: "Success saved on local")
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let isGoogleUrl = signInViewModel.expectGoogleUserUrl(url: urls)
        if isGoogleUrl.0 {
            signInViewModel.getTokenResponse(using: isGoogleUrl.1!) { result in
                switch result {
                case .success(let success):
                    self.driveController.accessToken = success.accessToken
                    self.showNotification(message: "Google account connected")
                    self.signInViewModel.requestProfile(idToken: success.idToken)
                    self.mainViewModel.hasLogon = self.signInViewModel.profile != nil
                    self.getFileInDrive()
                case .failure(let error):
                    log("reason --> \(error.localizedDescription)")
                    self.showNotification(message: "Google account failed")
                }

                log(self.signInViewModel.logonStatus)
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
    }

    func openStartingWindow() {
        if startingWindow == nil {
            let startingView = StartingView()
            let windowView = NSHostingController(rootView: startingView)

            startingWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
                    styleMask: [.titled, .closable],
                    backing: .buffered, defer: false)
            startingWindow.title = "notatod!"
            startingWindow.center()
            startingWindow.setFrameAutosaveName("Preferences")
            startingWindow.isReleasedWhenClosed = false
            startingWindow.contentView = windowView.view
            startingWindow.appearance = userDefaultController.theme()
        }

        startingWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openPreferencesWindow() {
        checkGoogleAuthEnable()
        checkUpdateAvailable()
        userDefaultController.saveNotes(notes: mainViewModel.notes)

        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
                    .environmentObject(signInViewModel)

            let windowView = NSHostingController(rootView: preferencesView)
            preferencesWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                    styleMask: [.titled, .closable],
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

    func openAccountWindow() {
        checkGoogleAuthEnable()
        checkUpdateAvailable()
        userDefaultController.saveNotes(notes: mainViewModel.notes)

        if accountWindow == nil {
            let accountView = AccountView()
                    .frame(width: 480, height: 300)
                    .environmentObject(signInViewModel)

            let windowView = NSHostingController(rootView: accountView)
            accountWindow = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                    styleMask: [.titled, .closable],
                    backing: .buffered, defer: false)
            accountWindow.title = "Account"
            accountWindow.center()
            accountWindow.setFrameAutosaveName("Account")
            accountWindow.isReleasedWhenClosed = false
            accountWindow.contentView = windowView.view
            accountWindow.appearance = userDefaultController.theme()
        }

        accountWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func changeThemeNow() {
        popover.appearance = userDefaultController.theme()
        preferencesWindow.appearance = userDefaultController.theme()
    }

    func changeSize() {
        if userDefaultController.popoverWindowSize() == 1 {
            popover.contentSize = NSSize(width: 1000, height: 600)
            userDefaultController.savePopoverWindow(typeSize: 2)
        } else {
            popover.contentSize = NSSize(width: 800, height: 400)
            userDefaultController.savePopoverWindow(typeSize: 1)
        }
    }

}
