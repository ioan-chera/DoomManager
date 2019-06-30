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

    /// Just tell it to bring attention to item index without selecting
    func wadOperationsBringAttention(index: Int)

    /// Start multiselect session. This one both brings attention and highlights something
    func wadOperationsBeginMultiAction()
    /// Add item to multiselect session (or just select if not in a session)
    func wadOperationsHighlight(index: Int)
    func wadOperationsReportAction(name: String)
    /// End and commit a select session
    func wadOperationsEndMultiAction()
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
    func renameLump(index: Int, as name: String) {
        let lump = wad.lumps[index]
        let oldName = lump.name
        let oldNameBytes = lump.nameBytes
        lump.name = name

        // only register real changes
        if oldNameBytes == lump.nameBytes {
            return
        }
        delegate?.wadOperationsUndo {
            self.renameLump(index: index, as: oldName)
        }
        delegate?.wadOperationsUpdateView()
        delegate?.wadOperationsHighlight(index: index)
        delegate?.wadOperationsReportAction(name: "Renamed")
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
        delegate?.wadOperationsHighlight(index: index)
        delegate?.wadOperationsReportAction(name: "Added")
    }

    ///
    /// Delete one lump
    ///
    private func deleteLump(index: Int) {
        delegate?.wadOperationsBringAttention(index: index)
        let lump = wad.deleteLump(index: index)
        delegate?.wadOperationsUndo {
            self.add(lump: lump, index: index)
        }
        delegate?.wadOperationsUpdateView()
        delegate?.wadOperationsReportAction(name: "Deleted")
    }

    ///
    /// Holds both multi-select boundaries and also sets up undo
    ///
    private func beginMultiHighlight() {
        delegate?.wadOperationsBeginMultiAction()
        delegate?.wadOperationsUndo {
            self.endMultiHighlight()
        }
    }
    private func endMultiHighlight() {
        delegate?.wadOperationsEndMultiAction()
        delegate?.wadOperationsUndo {
            self.beginMultiHighlight()
        }
    }

    ///
    /// Delete lumps
    ///
    func deleteLumps(indices: IndexSet) {
        if indices.isEmpty {
            return
        }

        beginMultiHighlight()
        for index in indices.reversed() {
            deleteLump(index: index)
        }
        endMultiHighlight()
    }

    private func moveLump(index: Int, toIndex: Int) {
        if index == toIndex {
            return
        }
        let lump = wad.deleteLump(index: index)
        wad.add(lump: lump, index: toIndex)
        delegate?.wadOperationsUndo {
            self.moveLump(index: toIndex, toIndex: index)
        }
        delegate?.wadOperationsUpdateView()
        delegate?.wadOperationsHighlight(index: toIndex)
        delegate?.wadOperationsReportAction(name: "Moved")
    }

    ///
    /// Move lumps up
    ///
    func moveLumpsUp(indices: IndexSet) {
        let newIndices = indices.decremented(minimum: 0)
        if newIndices == indices {
            return
        }
        let newIndicesArray = Array(newIndices)
        var pos = 0

        beginMultiHighlight()
        for index in Array(indices) {
            moveLump(index: index, toIndex: newIndicesArray[pos])
            pos += 1
        }
        endMultiHighlight()
    }

    ///
    /// Move them now
    ///
    func moveLumpsDown(indices: IndexSet) {
        let newIndices = indices.incremented(maximum: wad.lumps.count - 1)
        if newIndices == indices {
            return
        }
        let newIndicesArray = Array(Array(newIndices).reversed())
        var pos = 0

        beginMultiHighlight()
        for index in indices.reversed() {
            moveLump(index: index, toIndex: newIndicesArray[pos])
            pos += 1
        }
        endMultiHighlight()
    }

    ///
    /// Load many lumps from URLs, potentially populating post given indices
    ///
    func importLumps(urls: [URL], afterIndex: Int?) {

        // Try to validate ahead of time
        let lumps = urls.compactMap { Lump(url: $0) }
        // All failed? Abort. This is to prevent any ineffectual "dirtyness" states.
        if lumps.isEmpty {
            return
        }

        var index = (afterIndex ?? -1) + 1

        beginMultiHighlight()
        for lump in lumps {
            add(lump: lump, index: index)
            index += 1
        }
        endMultiHighlight()
    }
}
