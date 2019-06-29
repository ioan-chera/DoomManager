//
//  DocumentOperations.swift
//  DoomManager
//
//  Created by ioan on 24/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

///
/// Whoever listens to wad operation updates. Usually a document
///
protocol WadOperationsDelegate: class {
    func wadOperationsUndo(closure: @escaping () -> Void)
    func wadOperationsUpdateView()
}

///
/// User operations on a wad document
///
class WadOperations {
    private let wad: Wad
    weak var delegate: WadOperationsDelegate?

    init(wad: Wad) {
        self.wad = wad
    }

    ///
    /// Lump rename
    ///
    func rename(lump: Lump, as name: String) {
        let oldName = lump.name
        let oldNameBytes = lump.nameBytes
        lump.name = name

        // only register real changes
        if oldNameBytes == lump.nameBytes {
            return
        }
        delegate?.wadOperationsUndo {
            self.rename(lump: lump, as: oldName)
        }
        delegate?.wadOperationsUpdateView()
    }

    ///
    /// Adds a prepared lump to the wad
    ///
    private func add(lump: Lump, index: Int) {
        wad.add(lump: lump, index: index)
        delegate?.wadOperationsUndo {
            self.deleteLump(index: index)
        }
        delegate?.wadOperationsUpdateView()
    }

    ///
    /// Delete one lump
    ///
    private func deleteLump(index: Int) {
        let lump = wad.delete(lumpAtIndex: index)
        delegate?.wadOperationsUndo {
            self.add(lump: lump, index: index)
        }
        delegate?.wadOperationsUpdateView()
    }

    ///
    /// Delete lumps
    ///
    func deleteLumps(indices: IndexSet) {
        for index in Array(indices) {
            deleteLump(index: index)
        }
    }
}
