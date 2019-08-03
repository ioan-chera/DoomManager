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

extension NSTableView {
    ///
    /// Scrolls to a row by animating
    /// https://stackoverflow.com/a/8480325
    ///
    func animateToRow(index: Int) {
        // Also make sure not to center pointlessly
        if self.rows(in: self.visibleRect).contains(index) {
            return
        }
        let rowRect = self.rect(ofRow: index)
        guard let viewRect = self.superview?.frame else {
            return
        }
        var scrollOrigin = rowRect.origin
        scrollOrigin.y += (rowRect.height - viewRect.height) / 2
        if scrollOrigin.y < 0 {
            scrollOrigin.y = 0
        }
        self.superview?.animator().setBoundsOrigin(scrollOrigin)
    }
}
