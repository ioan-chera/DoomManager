//
//  ClickableLabel.swift
//  DoomManager
//
//  Created by ioan on 06/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

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
