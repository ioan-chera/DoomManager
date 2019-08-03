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
/// Clickable label
///
class ClickableLabel: NSTextField {

    var info: Any?  // any associated data

    ///
    /// https://stackoverflow.com/a/13266513/11738219
    ///
    override func resetCursorRects() {
        if isEnabled {
            addCursorRect(bounds, cursor: .pointingHand)
        } else {
            super.resetCursorRects()
        }
    }

    ///
    /// Do the click
    ///
    override func mouseUp(with event: NSEvent) {
        // https://stackoverflow.com/a/4631004/11738219
        // Make sure to reject mouse-up if not in view
        if !isEnabled {
            super.mouseUp(with: event)
            return
        }
        guard let action = action else {
            super.mouseUp(with: event)
            return
        }
        let globalLocation = NSEvent.mouseLocation
        guard let windowLocation = window?.convertPoint(fromScreen: globalLocation) else {
            super.mouseUp(with: event)
            return
        }
        let viewLocation = convert(windowLocation, from: nil)
        if !NSPointInRect(viewLocation, bounds) {
            super.mouseUp(with: event)
            return
        }
        NSApp.sendAction(action, to: target, from: self)
        return
    }
}
