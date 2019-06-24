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
class LumpViewDelegate : NSObject, NSTableViewDataSource {

    private let columnIndexLumpName = 0
    private let columnIndexLumpType = 1

    weak var document: Document?

    func numberOfRows(in tableView: NSTableView) -> Int {
        return document?.wad.lumps.count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let document = document else {
            return nil
        }
        if tableColumn === tableView.tableColumns[columnIndexLumpName] {
            return document.wad.lumps[row].name
        } else if (tableColumn === tableView.tableColumns[columnIndexLumpType]) {
            return analyzeLumpType(document.wad.lumps[row]).rawValue
        }
        return nil
    }
}
