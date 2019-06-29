//
//  Document.swift
//  DoomManager
//
//  Created by ioan on 22/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Cocoa

///
/// The document
///
class Document: NSDocument, WadOperationsDelegate {

    private let wad = Wad()
    private let operations: WadOperations

    @IBOutlet var lumpList: NSTableView!
    @IBOutlet var lumpListDelegate: LumpViewDelegate!
    @IBOutlet var mainWindow: NSWindow! // need this because "window" is ambiguous

    override init() {
        operations = WadOperations(wad: wad)
        super.init()
        // Add your subclass-specific initialization here.
        operations.delegate = self
    }

    ///
    /// Enable autosave and versions
    ///
    override class var autosavesInPlace: Bool {
        return true
    }

    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        lumpListDelegate.set(wad: wad, operations: operations)
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

    ///
    /// Delegate asked to send an undoer
    ///
    func wadOperationsUndo(closure: @escaping () -> Void) {
        undoManager?.registerUndo(withTarget: self) {_ in
            closure()
        }
    }

    ///
    /// Called when the wad operation demands an update
    ///
    func wadOperationsUpdateView() {
        lumpList.reloadData()
    }

    ///
    /// Highlight a cell or add it to the list if during a session
    ///
    private var multiHighlightIndices: IndexSet?
    private var multiHighlightRefs = 0
    func wadOperationsHighlight(index: Int) {
        if multiHighlightIndices != nil {
            multiHighlightIndices?.insert(index)
        } else {    // otherwise it's just a unit
            lumpList.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: true)
        }
    }

    ///
    /// Starting a session. NOTE: this must be put into undo because it's called from the operation
    ///
    func wadOperationsBeginMultiHighlight() {
        if multiHighlightRefs == 0 {
            multiHighlightIndices = IndexSet()
        }
        multiHighlightRefs += 1
    }

    ///
    /// Ending and committing a session
    ///
    func wadOperationsEndMultiHighlight() {
        if let indices = multiHighlightIndices {
            if multiHighlightRefs == 1 {
                lumpList.selectRowIndexes(indices, byExtendingSelection: false)
                multiHighlightIndices = nil
            }
        }
        multiHighlightRefs -= 1
        assert(multiHighlightRefs >= 0)
    }

    ///
    /// Validate menus
    ///
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        // Actions run on selected table items
        let selectionActions = Set<Selector>([
            #selector(Document.delete(_:)),
            #selector(Document.moveLumpDownClicked(_:)),
            #selector(Document.moveLumpUpClicked(_:))
        ])

        if menuItem.action != nil && selectionActions.contains(menuItem.action!) {
            return !lumpList.selectedRowIndexes.isEmpty
        }
        return super.validateMenuItem(menuItem)
    }

    ///
    /// Delete responder
    ///
    @objc func delete(_ sender: Any?) {
        operations.deleteLumps(indices: lumpList.selectedRowIndexes)
    }

    ///
    /// Move up clicked
    ///
    @IBAction func moveLumpUpClicked(_ sender: Any?) {
        operations.moveLumpsUp(indices: lumpList.selectedRowIndexes)
    }

    ///
    /// Move down clicked
    ///
    @IBAction func moveLumpDownClicked(_ sender: Any?) {
        operations.moveLumpsDown(indices: lumpList.selectedRowIndexes)
    }

    ///
    /// Import one or more lumps
    ///
    @IBAction func importLumpClicked(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.title = "Import Lumps"
        panel.prompt = "Import"
        panel.beginSheetModal(for: mainWindow) { response in
            if response == .OK {
                self.operations.importLumps(urls: panel.urls, afterIndex: self.lumpList.selectedRowIndexes.max())
            }
        }
    }
}
