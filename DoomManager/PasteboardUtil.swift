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
