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

    ///
    /// Moves one lump inside the wad
    ///
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
    func moveLumpsUp(indices: IndexSet, to newIndices: IndexSet) {
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
    func moveLumpsDown(indices: IndexSet, to newIndices: IndexSet) {
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
        let lumps = urls.compactMap { try? Lump(url: $0) }
        // All failed? Abort. This is to prevent any ineffectual "dirtyness" states.
        if lumps.isEmpty {
            return
        }

        add(lumps: lumps, afterIndex: afterIndex)
    }

    ///
    /// Adds multiple lumps after an index
    ///
    func add(lumps: [Lump], afterIndex: Int?) {
        var index = (afterIndex ?? -1) + 1

        beginMultiHighlight()
        for lump in lumps {
            add(lump: lump, index: index)
            index += 1
        }
        endMultiHighlight()
    }
}
