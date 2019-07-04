//
//  AppDelegate.swift
//  DoomManager
//
//  Created by ioan on 22/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        do {
            try ensureDirs()
        } catch let error {
            NSApp.presentError(error)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    ///
    /// Get current document quickly
    ///
    var document: Document? {
        return NSDocumentController.shared.currentDocument as? Document
    }
}
