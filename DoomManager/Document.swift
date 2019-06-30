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
class Document: NSDocument, WadDelegate, WadOperationsDelegate {

    private let wad = Wad()
    private let operations: WadOperations

    @IBOutlet var lumpList: NSTableView!
    @IBOutlet var lumpListDelegate: LumpViewDelegate!
    @IBOutlet var lumpCountStatus: NSTextField!
    @IBOutlet var lastActionStatus: NSTextField!
    @IBOutlet var mainWindow: NSWindow! // need this because "window" is ambiguous

    override init() {
        operations = WadOperations(wad: wad)
        super.init()
        // Add your subclass-specific initialization here.
        operations.delegate = self
        wad.delegate = self
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
        wadLumpCountUpdated(wad.lumps.count)    // calling this is needed
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
    /// Report status
    ///
    private func reportStatus(text: String) {
        lastActionStatus.isHidden = false
        lastActionStatus.stringValue = text
        lastActionStatus.sizeToFit()
    }

    ///
    /// Delegate asked lump count update
    ///
    func wadLumpCountUpdated(_ count: Int) {
        if lumpCountStatus != nil {
            lumpCountStatus.stringValue = countedWord(singular: "lump", plural: "lumps", count: count)
            
            // Most likely selection changed, so update that too
            var notification = Notification(name: NSTableView.selectionDidChangeNotification)
            notification.object = lumpList
            lumpListDelegate.tableViewSelectionDidChange(notification)
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
    private var multiActionReport = [String: Int]()
    func wadOperationsHighlight(index: Int) {
        if multiHighlightIndices != nil {
            multiHighlightIndices?.insert(index)
        } else {    // otherwise it's just a unit
            lumpList.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: true)
            wadOperationsBringAttention(index: index)
        }
    }

    ///
    /// Helper to convert the report to a text
    ///
    private func consumeReport() {
        var text = ""
        var first = true
        for (key, value) in multiActionReport {
            if !first {
                text.append(", \(key.lowercased())")
            } else {
                text.append("\(key)")
            }
            if undoManager?.isUndoing == true {
                text.append(" back")
            }
            text.append(" \(countedWord(singular: "lump", plural: "lumps", count: value))")
            first = false
        }
        reportStatus(text: text)
        multiActionReport.removeAll()
    }

    ///
    /// Report an action to show it on the status bar
    ///
    func wadOperationsReportAction(name: String) {
        if multiHighlightIndices != nil {
            if let _ = multiActionReport[name] {
                multiActionReport[name]! += 1
            } else {
                multiActionReport[name] = 1
            }
        } else {
            multiActionReport[name] = 1
            consumeReport()
        }
    }

    ///
    /// Starting a session. NOTE: this must be put into undo because it's called from the operation
    ///
    func wadOperationsBeginMultiAction() {
        if multiHighlightRefs == 0 {
            multiHighlightIndices = IndexSet()
        }
        multiHighlightRefs += 1
    }

    ///
    /// Ending and committing a session
    ///
    func wadOperationsEndMultiAction() {
        if let indices = multiHighlightIndices {
            if multiHighlightRefs == 1 {
                lumpList.selectRowIndexes(indices, byExtendingSelection: false)
                multiHighlightIndices = nil

                if !indices.isEmpty {
                    wadOperationsBringAttention(index: indices.max()!)
                }

                consumeReport()
            }
        }
        multiHighlightRefs -= 1
        assert(multiHighlightRefs >= 0)
    }

    ///
    /// Animates to a row (used when selecting isn't appropriate
    ///
    func wadOperationsBringAttention(index: Int) {
        lumpList.animateToRow(index: index)
    }

    ///
    /// Validate menus
    ///
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        // Actions run on selected table items
        let selectionActions = Set<Selector>([
            #selector(Document.delete(_:)),
            #selector(Document.exportLumpClicked(_:)),
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

    ///
    /// Export one or more lumps
    ///
    @IBAction func exportLumpClicked(_ sender: Any?) {
        let lumpCount = lumpList.selectedRowIndexes.count
        if lumpCount == 1 {
            let panel = NSSavePanel()
            panel.title = "Export Lump"
            panel.prompt = "Export"
            panel.canCreateDirectories = true
            let lump = wad.lumps[lumpList.selectedRow]
            //
            // TODO i6: guess format and suggest appropriate extension
            //
            panel.nameFieldStringValue = lump.name + ".lmp"
            panel.beginSheetModal(for: mainWindow) { response in
                if response == .OK {
                    // this is not an operation
                    guard let url = panel.url else {
                        return
                    }
                    guard (try? lump.write(url: url)) != nil else {
                        let alert = NSAlert()
                        alert.alertStyle = .warning
                        alert.messageText = "Couldn't export lump '\(lump.name)' to '\(url.path)'"
                        alert.informativeText = "Path may be invalid or inaccessible. Check if you have write access to that location."
                        alert.beginSheetModal(for: self.mainWindow, completionHandler: nil)
                        self.reportStatus(text: "Failed exporting 1 lump")
                        return
                    }
                    self.reportStatus(text: "Exported 1 lump")
                }
            }
        } else {
            // Multiple selection
            let panel = NSOpenPanel()   // "open" a folder for writing into
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.title = "Export \(lumpCount) Lumps"
            panel.prompt = "Export"
            panel.message = "All \(lumpCount) lumps will be exported to selected folder."
            panel.canCreateDirectories = true
            panel.beginSheetModal(for: mainWindow) { response in
                if response == .OK {
                    guard let url = panel.url else {
                        return
                    }
                    let lumps = (self.wad.lumps as NSArray).objects(at: self.lumpList.selectedRowIndexes) as! [Lump]
                    let filenames = lumps.map { $0.name + ".lmp" }
                    let overwritten = filenames.compactMap { filename -> String? in
                        let url = url.appendingPathComponent(filename)
                        return FileManager.default.fileExists(atPath: url.path) ? filename : nil
                    }

                    ///
                    /// Nested function, needed because of make-sure alert
                    ///
                    func doExport() {
                        var failures = [String]()
                        for (lump, filename) in zip(lumps, filenames) {
                            let lumpURL = url.appendingPathComponent(filename)
                            if (try? lump.write(url: lumpURL)) == nil {
                                failures.append(lump.name)
                            }
                        }

                        if !failures.isEmpty {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.messageText = "Failed exporting the following " + countedWord(singular: "lump", plural: "lumps", count: failures.count) + " to '\(url.path)'"
                            alert.informativeText = stringEnumeration(array: failures, maxCount: 20, completionPunctuation: ".") + "\n\nCheck if you have write access to that location."
                            alert.beginSheetModal(for: self.mainWindow, completionHandler: nil)

                            let lumpDisplay = countedWord(singular: "lump", plural: "lumps", count: lumps.count - failures.count)
                            let failedDisplay = countedWord(singular: "lump", plural: "lumps", count: failures.count)
                            self.reportStatus(text: "Exported \(lumpDisplay), failed \(failedDisplay)")
                        } else {
                            self.reportStatus(text: "Exported \(countedWord(singular: "lump", plural: "lumps", count: lumps.count))")
                        }


                    }

                    if !overwritten.isEmpty {
                        let alert = NSAlert()
                        alert.alertStyle = .critical
                        alert.messageText = "The following files already exist at '\(url.path)' and will be overwritten:"
                        alert.informativeText = stringEnumeration(array: overwritten, maxCount: 20, completionPunctuation: ".") + "\n\nAre you sure you want to overwrite them?"
                        alert.addButton(withTitle: "Overwrite")
                        alert.addButton(withTitle: "Cancel")
                        alert.beginSheetModal(for: self.mainWindow) { response in
                            if response == .alertFirstButtonReturn {
                                doExport()
                            }
                        }
                    } else {
                        doExport()
                    }
                }
            }
        }
    }
}
