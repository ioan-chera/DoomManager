//
//  LumpViewDelegate.swift
//  DoomManager
//
//  Created by ioan on 24/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import AppKit
import Foundation

///
/// Delegate of the lump table
///
class LumpViewDelegate : NSObject, NSTableViewDataSource, NSTableViewDelegate {

    var wad: Wad?

    ///
    /// Required number of rows
    ///
    func numberOfRows(in tableView: NSTableView) -> Int {
        return wad?.lumps.count ?? 0
    }

    ///
    /// Get the view for the table at the given column
    ///
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "lump" {
            let lumpName = wad?.lumps[row].name ?? ""
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("lump"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = lumpName
                return cell
            }
        }
        return nil
    }
}
