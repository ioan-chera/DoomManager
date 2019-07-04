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
    @IBOutlet var lumpCountStatus: NSTextField!
    @IBOutlet var lastActionStatus: NSTextField!
    @IBOutlet var mainWindow: NSWindow! // need this because "window" is ambiguous
    @IBOutlet var lumpFilterBox: NSSearchField!

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
        wadOperationsUpdateView()

        if let cell = lumpFilterBox.cell as? NSSearchFieldCell {
            cell.searchButtonCell?.image = NSImage(named: "line.horizontal.3.decrease.circle")
        }
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
        lumpListDelegate.updateFilter()
        lumpList.reloadData()
        lumpCountStatus.stringValue = countedWord(singular: "lump", plural: "lumps", count: wad.lumps.count)
        // Most likely selection changed, so update that too
        var notification = Notification(name: NSTableView.selectionDidChangeNotification)
        notification.object = lumpList
        lumpListDelegate.tableViewSelectionDidChange(notification)
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
            lumpList.selectRowIndexes(IndexSet(integer: lumpListDelegate.filtered(index: index)), byExtendingSelection: true)
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
                lumpList.selectRowIndexes(lumpListDelegate.filtered(indices: indices), byExtendingSelection: false)
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
        lumpList.animateToRow(index: lumpListDelegate.filtered(index: index))
    }

    ///
    /// Validate menus
    ///
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        // Actions run on selected table items
        let selectionActions = Set<Selector>([
            #selector(Document.copy(_:)),
            #selector(Document.cut(_:)),
            #selector(Document.delete(_:)),
            #selector(Document.exportLumpClicked(_:)),
            #selector(Document.moveLumpDownClicked(_:)),
            #selector(Document.moveLumpUpClicked(_:))
        ])

        if menuItem.action == #selector(Document.paste(_:)) {
            let pasteboard = NSPasteboard.general
            return pasteboard.canReadObject(forClasses: [Lump.self], options: nil)
        }

        if menuItem.action != nil && selectionActions.contains(menuItem.action!) {
            return !lumpList.selectedRowIndexes.isEmpty
        }

        return super.validateMenuItem(menuItem)
    }

    ///
    /// Delete responder
    ///
    @objc func delete(_ sender: Any?) {
        operations.deleteLumps(indices: lumpListDelegate.defiltered(indices: lumpList.selectedRowIndexes))
    }

    ///
    /// Move up clicked
    ///
    @IBAction func moveLumpUpClicked(_ sender: Any?) {
        let def = lumpListDelegate.defiltered(indices:)
        let aboveIndices = lumpList.selectedRowIndexes.decremented(minimum: 0)
        operations.moveLumpsUp(indices: def(lumpList.selectedRowIndexes), to: def(aboveIndices))
    }

    ///
    /// Move down clicked
    ///
    @IBAction func moveLumpDownClicked(_ sender: Any?) {
        let def = lumpListDelegate.defiltered(indices:)
        let belowIndices = lumpList.selectedRowIndexes.incremented(maximum: lumpList.numberOfRows - 1)
        operations.moveLumpsDown(indices: def(lumpList.selectedRowIndexes), to: def(belowIndices))
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
                if let max = self.lumpList.selectedRowIndexes.max() {
                    self.operations.importLumps(urls: panel.urls, afterIndex: self.lumpListDelegate.defiltered(index: max))
                } else {
                    self.operations.importLumps(urls: panel.urls, afterIndex: nil)
                }
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
            let lump = wad.lumps[lumpListDelegate.defiltered(index: lumpList.selectedRow)]
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
                    let lumps = arrayObjects(self.wad.lumps, indices: self.lumpListDelegate.defiltered(indices: self.lumpList.selectedRowIndexes))
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
                        var writtenFromWad = Set<URL>()
                        for (lump, filename) in zip(lumps, filenames) {
                            var lumpURL = url.appendingPathComponent(filename)
                            if writtenFromWad.contains(lumpURL) {
                                // If this is the second lump of the same name, we have no choice
                                // but to auto-rename it, otherwise it becomes impossible to export
                                // like-named lumps together
                                lumpURL = lumpURL.numberRenamed()
                            } else {
                                writtenFromWad.insert(lumpURL)
                            }
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

    ///
    /// Implement clipboard copy
    ///
    @IBAction func copy(_ sender: Any?) {
        let lumps = arrayObjects(wad.lumps, indices: lumpListDelegate.defiltered(indices: lumpList.selectedRowIndexes))
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var repeats = [URL: Int]()  // in case of repeats, perform incremention. Do not rely on OS
                                    // to luckily do this with promised files

        for lump in lumps {
            var url = tempClipboardPathURL.appendingPathComponent(lump.name + ".lmp")
            if let numRepeats = repeats[url] {
                repeats[url] = numRepeats + 1
                url = tempClipboardPathURL.appendingPathComponent("\(lump.name) \(numRepeats).lmp")
            } else {
                repeats[url] = 1
            }
            let item = LumpURLProvider.Item()
            item.lump = lump
            item.url = url
            let provider = LumpURLProvider()
            item.setDataProvider(provider, forTypes: lump.writableTypes(for: pasteboard) + [.fileURL])
            pasteboard.writeObjects([item])
        }

        reportStatus(text: "Copied \(countedWord(singular: "lump", plural: "lumps", count: lumps.count)) to clipboard")
    }

    ///
    /// Implement clipboard paste
    ///
    @IBAction func paste(_ sender: Any?) {
        // TODO i8: can be filtered
        let pasteboard = NSPasteboard.general
        if pasteboard.canReadObject(forClasses: [Lump.self], options: nil) {
            if let objectsToPaste = pasteboard.readObjects(forClasses: [Lump.self], options: nil) as? [Lump] {
                // We have them. Add them where they should be
                if let max = lumpList.selectedRowIndexes.max() {
                    operations.add(lumps: objectsToPaste, afterIndex: lumpListDelegate.defiltered(index: max))
                } else {
                    operations.add(lumps: objectsToPaste, afterIndex: nil)
                }
            }
        }
    }

    ///
    /// Implement clipboard cut
    ///
    @IBAction func cut(_ sender: Any?) {
        copy(sender)
        delete(sender)
    }

    ///
    /// Necessary to provide URLs
    ///
    class LumpURLProvider: NSObject, NSPasteboardItemDataProvider {
        ///
        /// The pasteboard item. Holds reference to lump
        ///
        class Item: NSPasteboardItem {
            var url: URL!
            var lump: Lump!
        }
        ///
        /// The actual providing function
        ///
        func pasteboard(_ pasteboard: NSPasteboard?, item: NSPasteboardItem, provideDataForType type: NSPasteboard.PasteboardType) {
            // Retrieve the URL from the item

            let lumpItem = item as! Item

            if type != .fileURL {
                let clipData = lumpItem.lump.pasteboardPropertyList(forType: type)
                item.set(content: clipData, forType: type)
                return
            }

            item.setData(lumpItem.url.dataRepresentation, forType: .fileURL)

            guard (try? lumpItem.lump.write(url: lumpItem.url)) != nil else {
                Swift.print("Failed outputting to \(String(describing: lumpItem.url))")
                return
            }
        }

        ///
        /// When ready to delete, delete all junk from path, to cleanup
        ///
        func pasteboardFinishedWithDataProvider(_ pasteboard: NSPasteboard) {
            guard let junk = try? FileManager.default.contentsOfDirectory(atPath: tempClipboardPathURL.path).map({ tempClipboardPathURL.appendingPathComponent($0) }) else {
                return
            }
            for url in junk {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    ///
    /// User is searching
    ///
    var previousSearchString = ""
    @IBAction func searchBoxUpdated(_ sender: Any?) {
        let currentString = lumpFilterBox.stringValue
        let realRow: Int?
        // TODO: preserve highlighting ALSO when visiting superior one
        if previousSearchString.localizedCaseInsensitiveContains(currentString) || currentString.isEmpty {
            // We have a search situation
            let row = lumpList.selectedRow
            realRow = row != -1 ? lumpListDelegate.defiltered(index: row) : nil
        } else {
            realRow = nil
        }

        lumpListDelegate.filterString = currentString
        wadOperationsUpdateView()

        if let realRow = realRow {
            wadOperationsHighlight(index: realRow)
        }

        previousSearchString = currentString
    }
}
