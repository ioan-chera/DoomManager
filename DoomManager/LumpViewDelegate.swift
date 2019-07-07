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

    private var filteredIndexMap = [Int: Int]()  // Maps full wad lump index to the filtered index
    private var filteredLumps = [(offset: Int, element: Lump)]() {
        didSet {
            filteredIndexMap = [:]
            filteredLumps.forEach { filteredIndexMap[$0.offset] = filteredIndexMap.count }
        }
    }
    var filterString = "" {
        didSet {
            updateFilter()
        }
    }

    ///
    /// Grouped setter
    ///
    func set(wad: Wad, operations: WadOperations) {
        self.wad = wad
        wadOperations = operations
        updateFilter()
    }

    ///
    /// Updates the filter according to string. Needs to be called after all wad changes (done by
    /// the WadOperations object).
    ///
    func updateFilter() {
        guard let wad = wad else {
            return
        }
        filteredIndexMap = [:]
        if filterString.isEmpty {
            filteredLumps = wad.lumps.enumerated().filter { element in true }
        } else {
            // We have a string
            let fold: (String) -> String = { $0.folding(options: .diacriticInsensitive, locale: .current) }
            let filter = fold(filterString.uppercased())
            filteredLumps = wad.lumps.enumerated().filter { fold($0.element.name).contains(filter) }
        }
    }

    ///
    /// Converts wadwide indices to filtered (displayed) ones
    ///
    func filtered(indices: IndexSet) -> IndexSet {
        return IndexSet(indices.compactMap { filteredIndexMap[$0] })
    }
    func filtered(index: Int) -> Int? {
        return filteredIndexMap[index]
    }

    ///
    /// Converts filter index to wadwide index
    ///
    func defiltered(indices: IndexSet) -> IndexSet {
        return IndexSet(indices.map { filteredLumps[$0].offset })
    }
    func defiltered(index: Int) -> Int {
        return filteredLumps[index].offset
    }

    ///
    /// Required number of rows
    ///
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredLumps.count
    }

    ///
    /// Get the view for the table at the given column
    ///
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier.rawValue == "lump" {
            let lumpName = filteredLumps[row].element.name
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("lump"), owner: nil) as? NSTableCellView {
                cell.textField?.stringValue = lumpName

                cell.textField?.tag = filteredLumps[row].offset // Need the lump index
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

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return filteredLumps[row].element
    }
}
