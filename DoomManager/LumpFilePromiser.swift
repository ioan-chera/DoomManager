/*
 DoomManager: Doom resource editor
 Copyright (C) 2019  Ioan Chera

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


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
        return result
    }

    ///
    /// Do the actual writing
    ///
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        let promiser = filePromiseProvider as! LumpFilePromiser
        do {
            try promiser.lump.write(url: url.sanitizedLump())
        } catch let error {
            completionHandler(error)
        }
    }
}
