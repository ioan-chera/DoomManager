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

        guard let lumpItem = item as? Item else {
            return
        }

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
