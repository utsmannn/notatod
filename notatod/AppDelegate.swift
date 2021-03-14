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
    let featureApiController = FeatureApiController()

    var cloudApi: CloudApi? = nil
    var cloudUserDefault: CloudUserDefault? = nil

    var authViewModel: AuthViewModel!
    var mainViewModel: MainViewModel!

    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var preferencesWindow: NSWindow!
    var accountWindow: NSWindow!

    var startingWindow: NSWindow!
    var startingView: StartingView?

    typealias UserNotification = NSUserNotification
    typealias UserNotificationCenter = NSUserNotificationCenter
    let UserNotificationDefaultSoundName = NSUserNotificationDefaultSoundName

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains(UserDefaultController.TAG) {
                log("\n\(key) : \n\(value) \n")
            }
        }

        openStartingWindow()
        checkUpdateAvailable()
        checkAuthTypeFeature { authEnable in
            self.setupInit(authType: authEnable)
        }

        setupKeyboardShortcut()
    }

    private func setupInit(authType: AuthType) {
        authViewModel = AuthViewModel(cloudApi: cloudApi)
        mainViewModel = MainViewModel(cloudApi: cloudApi)

        authViewModel.authType = authType
        authViewModel.checkSession { entity in
            self.mainViewModel.hasLogon = entity != nil
            self.mainViewModel.searchFileInDrive()
        }

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
    }

    func checkUpdateAvailable() {
        featureApiController.checkUpdateAvailable { os in
            let isUpdateAvailable = NSApplication.shared.AppVersionInt! < os.versionCode
            self.mainViewModel.isUpdateAvailable = isUpdateAvailable
            self.mainViewModel.version = os
        }
    }

    func checkAuthTypeFeature(authType: @escaping (AuthType) -> ()) {
        featureApiController.authServiceEnable { featureEnable in
            self.userDefaultController.saveAuthType(authType: featureEnable)
            switch featureEnable {
            case .google:
                self.cloudApi = GDriveController()
                self.cloudUserDefault = GoogleUserDefault()
                    /**/
            case .dropbox:
                self.cloudApi = DropboxController()
                self.cloudUserDefault = DropboxUserDefault()
            case .disable:
                self.cloudApi = nil
                self.cloudUserDefault = nil
            }

            DispatchQueue.main.async {
                authType(featureEnable)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
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
            self.mainViewModel.userDefault.saveNotes(notes: self.mainViewModel.notes)

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
            } else {
                self.showNotification(message: "Success saved on local")
            }
        }
    }


    func application(_ application: NSApplication, open urls: [URL]) {
        cloudApi?.getTokenResponse(using: urls[0]) { result in
            result.doOnSuccess { entity in
                log(entity.accessToken)
                self.cloudUserDefault?.saveAccessToken(token: entity.accessToken)
                self.cloudUserDefault?.saveAccountId(accountId: entity.profileId)
                self.showNotification(message: "Account linked")

                self.authViewModel.checkSession { entity in
                    self.mainViewModel.hasLogon = entity != nil
                    self.mainViewModel.searchFileInDrive()
                }
            }

            result.doOnFailure { error in
                log("reason --> \(error.localizedDescription)")
                self.showNotification(message: "Account failed")
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if mainViewModel != nil && authViewModel != nil {
            mainViewModel.setLocalNotes()
            if let button = statusBarItem.button {
                if popover.isShown {
                    popover.performClose(sender)
                } else {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                }
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
            startingView = StartingView()
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
        checkUpdateAvailable()
        userDefaultController.saveNotes(notes: mainViewModel.notes)

        if preferencesWindow == nil {
            let preferencesView = PreferencesView()
                    .environmentObject(authViewModel)
                    .environmentObject(mainViewModel)

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
        checkUpdateAvailable()
        userDefaultController.saveNotes(notes: mainViewModel.notes)

        if accountWindow == nil {
            let accountView = AccountView()
                    .frame(width: 480, height: 300)
                    .environmentObject(authViewModel)

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
