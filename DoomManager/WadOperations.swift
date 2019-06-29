//
//  DocumentOperations.swift
//  DoomManager
//
//  Created by ioan on 24/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

protocol WadOperationsDelegate: class {
    func wadOperationsUndo(closure: @escaping () -> Void)
    func wadOperationsUpdateView()
}

class WadOperations {
    private let wad: Wad
    var undo: UndoManager?

    weak var delegate: WadOperationsDelegate?

    init(wad: Wad) {
        self.wad = wad
    }

    func rename(lump: Lump, as name: String) {
        let currentName = lump.name
        lump.name = name
        undo?.registerUndo(withTarget: self, handler: { _ in
            self.rename(lump: lump, as: currentName)
        })
        delegate?.wadOperationsUpdateView()
    }
}
