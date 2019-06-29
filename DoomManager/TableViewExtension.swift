//
//  TableViewExtension.swift
//  DoomManager
//
//  Created by ioan on 30/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

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
