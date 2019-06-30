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

    private var wad: Wad?
    private var wadOperations: WadOperations?

    @IBOutlet var selectedCountStatus: NSTextField!

    ///
    /// Grouped setter
    ///
    func set(wad: Wad, operations: WadOperations) {
        self.wad = wad
        wadOperations = operations
    }

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

                cell.textField?.tag = row   // Need the lump index
                // Can't set these from Interface Builder, set them here
                cell.textField?.target = self
                cell.textField?.action = #selector(LumpViewDelegate.lumpNameEdited(_:))

                return cell
            }
        }
        return nil
    }

    ///
    /// Update selection status
    ///
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as! NSTableView
        let number = tableView.numberOfSelectedRows
        if number == 0 {
            selectedCountStatus.isHidden = true
        } else {
            selectedCountStatus.isHidden = false
            selectedCountStatus.stringValue = String(tableView.numberOfSelectedRows) + " selected"
        }
    }

    ///
    /// When lump name was edited
    ///
    @objc func lumpNameEdited(_ sender: AnyObject?) {
        if let field = sender as? NSTextField {
            wadOperations?.renameLump(index: field.tag, as: field.stringValue)
        }
    }
}
