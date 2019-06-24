//
//  Document.swift
//  DoomManager
//
//  Created by ioan on 22/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Cocoa

class Document: NSDocument, WadOperationsDelegate {

    let wad = Wad()
    @IBOutlet var lumpList: NSTableView!
    @IBOutlet var lumpViewDelegate: LumpViewDelegate!

    let operations: WadOperations

    override init() {
        operations = WadOperations(wad: wad)
        super.init()
        // Add your subclass-specific initialization here.
        operations.undo = undoManager
        operations.delegate = self
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func awakeFromNib() {
        lumpViewDelegate.document = self
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override fileWrapper(ofType:), write(to:ofType:), or write(to:ofType:for:originalContentsURL:) instead.
        return wad.serialized()
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type, throwing an error in case of failure.
        // Alternatively, you could remove this method and override read(from:ofType:) instead.
        // If you do, you should also override isEntireFileLoaded to return false if the contents are lazily loaded.
        do {
            try wad.read(data)
        } catch DMError.wadReading(let info) {
            throw NSError(domain: NSOSStatusErrorDomain, code: readErr, userInfo: [NSLocalizedDescriptionKey: info])
        }
    }

    func wadOperationsOccurred() {
        lumpList.reloadData()
    }
}
