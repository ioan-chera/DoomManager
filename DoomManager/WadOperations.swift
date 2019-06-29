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

    func wadOperationsBeginMultiHighlight()
    func wadOperationsHighlight(index: Int)
    func wadOperationsEndMultiHighlight()
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
    }

    ///
    /// Delete one lump
    ///
    private func deleteLump(index: Int) {
        let lump = wad.deleteLump(index: index)
        delegate?.wadOperationsUndo {
            self.add(lump: lump, index: index)
        }
        delegate?.wadOperationsUpdateView()
    }

    ///
    /// Delete lumps
    ///
    func deleteLumps(indices: IndexSet) {
        if indices.isEmpty {
            return
        }

        delegate?.wadOperationsBeginMultiHighlight()
        for index in Array(indices) {
            deleteLump(index: index)
        }
        delegate?.wadOperationsEndMultiHighlight()
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

        delegate?.wadOperationsBeginMultiHighlight()
        for index in Array(indices) {
            moveLump(index: index, toIndex: newIndicesArray[pos])
            pos += 1
        }
        delegate?.wadOperationsEndMultiHighlight()
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

        delegate?.wadOperationsBeginMultiHighlight()
        for index in Array(indices).reversed() {
            moveLump(index: index, toIndex: newIndicesArray[pos])
            pos += 1
        }
        delegate?.wadOperationsEndMultiHighlight()
    }

    ///
    /// Load many lumps from URLs, potentially populating post given indices
    ///
    func importLumps(urls: [URL], afterEachIndex indices: IndexSet) {

        // Try to validate ahead of time
        let lumps = urls.compactMap { Lump(url: $0) }
        // All failed? Abort. This is to prevent any ineffectual "dirtyness" states.
        if lumps.isEmpty {
            return
        }

        var fullIndices = Array(indices)
        while fullIndices.count < urls.count {
            fullIndices.append(fullIndices.max() ?? -1)
        }

        var pos = 0

        delegate?.wadOperationsBeginMultiHighlight()
        for url in urls {
            if let lump = Lump(url: url) {
                add(lump: lump, index: fullIndices[pos] + 1 + pos)
                pos += 1
            }
        }
        delegate?.wadOperationsEndMultiHighlight()
    }
}
