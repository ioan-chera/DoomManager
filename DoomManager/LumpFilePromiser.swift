//
//  LumpFilePromiser.swift
//  DoomManager
//
//  Created by ioan on 03/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import AppKit
import Foundation

///
/// Needed to be able to copy lumps both to themselves and to Finder
/// Thanks to https://buckleyisms.com/blog/how-to-actually-implement-file-dragging-from-your-app-on-mac/
///
class LumpFilePromiser: NSFilePromiseProvider {

    private static let customTypes: [NSPasteboard.PasteboardType] = [.init(Lump.uti), .string]

    let lump: Lump

    init(fileType: String, delegate: NSFilePromiseProviderDelegate, lump: Lump) {
        self.lump = lump
        super.init()
        self.fileType = fileType
        self.delegate = delegate
    }

    ///
    /// Add lump stuff
    ///
    override func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types = super.writableTypes(for: pasteboard)
        types.insert(contentsOf: LumpFilePromiser.customTypes, at: 0)
        return types
    }

    ///
    /// Don't use options for my types
    ///
    override func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        if LumpFilePromiser.customTypes.contains(type) {
            return []
        }
        return super.writingOptions(forType: type, pasteboard: pasteboard)
    }

    ///
    /// Property list vital
    ///
    override func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if LumpFilePromiser.customTypes.contains(type) {
            return lump.pasteboardPropertyList(forType: type)
        }
        return super.pasteboardPropertyList(forType: type)
    }
}

///
/// The information provider
///
class LumpFilePromiserDelegate: NSObject, NSFilePromiseProviderDelegate {
    ///
    /// Get lump filename
    ///
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        let result = (filePromiseProvider as! LumpFilePromiser).lump.name + ".lmp"
        print("Michael type: \(fileType) result: \(result)")
        return result
    }

    ///
    /// Do the actual writing
    ///
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        print("Jackson")
        let promiser = filePromiseProvider as! LumpFilePromiser
        do {
            try promiser.lump.write(url: url)
        } catch let error {
            completionHandler(error)
        }
    }
}
