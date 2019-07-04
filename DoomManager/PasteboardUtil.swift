//
//  PasteboardUtil.swift
//  DoomManager
//
//  Created by ioan on 04/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import AppKit
import Foundation

extension NSPasteboardItem {
    ///
    /// Abstractize away the casting I need to do to store data in an item correctly.
    ///
    @discardableResult func set(content: Any?, forType type: NSPasteboard.PasteboardType) -> Bool {
        if let data = content as? Data {
            return setData(data, forType: type)
        }
        if let string = content as? String {
            return setString(string, forType: type)
        }
        if let plist = content {
            return setPropertyList(plist, forType: type)
        }
        return false
    }
}
