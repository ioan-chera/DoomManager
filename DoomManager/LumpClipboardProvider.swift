//
//  LumpClipboardProvider.swift
//  DoomManager
//
//  Created by ioan on 07/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import AppKit
import Foundation

///
/// Necessary to provide URLs
///
class LumpClipboardProvider: NSObject, NSPasteboardItemDataProvider {
    ///
    /// The pasteboard item. Holds reference to lump
    ///
    class Item: NSPasteboardItem {
        var url: URL!
        var lump: Lump!
    }
    ///
    /// The actual providing function
    ///
    func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
        // Retrieve the URL from the item

        let lumpItem = item as! Item

        if type != .fileURL {
            let clipData = lumpItem.lump.pasteboardPropertyList(forType: type)
            item.set(content: clipData, forType: type)
            return
        }

        item.setData(lumpItem.url.dataRepresentation, forType: .fileURL)

        guard (try? lumpItem.lump.write(url: lumpItem.url)) != nil else {
            Swift.print("Failed outputting to \(String(describing: lumpItem.url))")
            return
        }
    }

    ///
    /// When ready to delete, delete all junk from path, to cleanup
    ///
    func pasteboardFinishedWithDataProvider(_ pasteboard: NSPasteboard) {
        guard let junk = try? FileManager.default.contentsOfDirectory(atPath: tempClipboardPathURL.path).map({ tempClipboardPathURL.appendingPathComponent($0) }) else {
            return
        }
        for url in junk {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
