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
    let driveController = GoogleDriveController()
    /*let dropboxController = DropboxController()
    let gDriveController = GDriveController()*/
    let featureApiController = FeatureApiController()

    var cloudApi: CloudApi!
    var cloudUserDefault: CloudUserDefault!

    //var signInViewModel: GoogleSignInViewModel!
    var authViewModel: AuthViewModel!
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
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.contains(UserDefaultController.TAG) {
                log("\n\(key) : \n\(value) \n")
            }
        }

        let authType = userDefaultController.authType
        switch authType {
        case .google:
            cloudApi = GDriveController()
            cloudUserDefault = GoogleUserDefault()
        case .dropbox:
            cloudApi = DropboxController()
            cloudUserDefault = DropboxUserDefault()
        }

        /*signInViewModel = GoogleSignInViewModel(
                userDefaultController: userDefaultController,
                driveController: driveController,
                featureApiController: featureApiController,
                dropboxController: dropboxController,
                gDriveController: gDriveController
        )*/


        //driveController.accessToken = signInViewModel.getAccessToken()
        //mainViewModel = MainViewModel(driveController: driveController, userDefaultController: userDefaultController)
        /*if signInViewModel.profile != nil {
            signInViewModel.logonStatus = .sign_in
        }

        mainViewModel.hasLogon = signInViewModel.profile != nil*/
        //getFileInDrive()

        authViewModel = AuthViewModel(cloudApi: cloudApi)
        mainViewModel = MainViewModel(cloudApi: cloudApi)
        mainViewModel.searchFileInDrive()
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

        openStartingWindow()
        checkGoogleAuthEnable()
        checkUpdateAvailable()
        setupKeyboardShortcut()
    }

    func checkUpdateAvailable() {
        featureApiController.checkUpdateAvailable { os in
            let isUpdateAvailable = NSApplication.shared.AppVersionInt! < os.versionCode
            //self.signInViewModel.version = os
            //self.signInViewModel.isUpdateAvailable = isUpdateAvailable
        }
    }

    func checkGoogleAuthEnable() {
        /*featureApiController.isGoogleAuthEnable { b in
            if !b {
                self.userDefaultController.clearDriveData()
            }
        }*/
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

        /*let isGoogleUrl = signInViewModel.expectGoogleUserUrl(url: urls)
        log("url incoming ... -> \(urls.map { url -> String in url.absoluteString })")
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
        } else {
            log(urls[0].absoluteString)
            dropboxController.getTokenResponse(using: urls[0]) { result in
                switch result {
                case .success(let success):
                    log(success.accessToken)
                case .failure(let error):
                    log("reason --> \(error.localizedDescription)")
                    self.showNotification(message: "Google account failed")
                }
            }
        }*/

        /*let cloudApi: some CloudApi = DropboxController()
        (cloudApi as! DropboxController).getTokenResponse(using: urls[0]) { (result: Result<notatod.DropboxController.T, Error>) in

        }*/

        /*let urlType = urlTypeChecking(urls: urls)
        switch urlType {
        case .google(let url):
            log("google --> \(url)")
            gDriveController.getTokenResponse(using: url) { result in
                switch result {
                case .success(let success):
                    log(success.accessToken)
                case .failure(let error):
                    log("reason --> \(error.localizedDescription)")
                    self.showNotification(message: "Google account failed")
                }
            }
        case .dropbox(let url):
            dropboxController.getTokenResponse(using: url) { (result: Result<notatod.DropboxController.T, Error>) in
                switch result {
                case .success(let success):
                    log(success.accessToken)
                case .failure(let error):
                    log("reason --> \(error.localizedDescription)")
                    self.showNotification(message: "Google account failed")
                }
            }
        case .none:
            log("incoming url")
        }*/

        cloudApi.getTokenResponse(using: urls[0]) { result in
            switch result {
            case .success(let success):
                log(success.accessToken)
                self.cloudUserDefault.saveAccessToken(token: success.accessToken)
                self.cloudUserDefault.saveAccountId(accountId: success.profileId)
            case .failure(let error):
                log("reason --> \(error.localizedDescription)")
                self.showNotification(message: "Account failed")
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
                    .environmentObject(authViewModel)

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
                    .environmentObject(authViewModel)

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
