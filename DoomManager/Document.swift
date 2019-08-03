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
    @IBOutlet var showInFinderLink: ClickableLabel!

    // MARK: Base document methods

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

        showInFinderLink.sizeToFit()
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

    // MARK: WadOperationsDelegate

    ///
    /// Report status
    ///
    private func reportStatus(text: String, finderLinkURL: URL? = nil) {
        lastActionStatus.isHidden = false
        lastActionStatus.stringValue = /*finderLinkURL == nil ? text : */text + "."
        lastActionStatus.sizeToFit()

        if let finderLinkURL = finderLinkURL {
            showInFinderLink.isHidden = false
            showInFinderLink.frame.origin.x = lastActionStatus.frame.maxX
            showInFinderLink.info = finderLinkURL
            showInFinderLink.toolTip = finderLinkURL.path
        } else {
            showInFinderLink.isHidden = true
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
        } else if let filteredIndex = lumpListDelegate.filtered(index: index) {    // otherwise it's just a unit
            lumpList.selectRowIndexes(IndexSet(integer: filteredIndex), byExtendingSelection: true)
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

                if let max = indices.max() {
                    wadOperationsBringAttention(index: max)
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
        if let filteredIndex = lumpListDelegate.filtered(index: index) {
            lumpList.animateToRow(index: filteredIndex)
        }
    }

    // MARK: Menu actions

    ///
    /// Validate menus
    ///
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {

        guard let action = menuItem.action else {
            return super.validateMenuItem(menuItem)
        }

        switch action {
        case #selector(Document.paste(_:)):
            let pasteboard = NSPasteboard.general
            return pasteboard.canReadObject(forClasses: [Lump.self], options: nil)

        case #selector(Document.copy(_:)),
             #selector(Document.cut(_:)),
             #selector(Document.delete(_:)),
             #selector(Document.exportLumpClicked(_:)),
             #selector(Document.moveLumpDownClicked(_:)),
             #selector(Document.moveLumpUpClicked(_:)),
             #selector(Document.performFindPanelAction(_:)) where menuItem.tag == Int(NSFindPanelAction.setFindString.rawValue):
            return !lumpList.selectedRowIndexes.isEmpty
        case #selector(Document.performFindPanelAction(_:)):
            return [NSFindPanelAction.showFindPanel, NSFindPanelAction(rawValue: 12)].contains(NSFindPanelAction(rawValue: UInt(menuItem.tag)))
        default:
            return super.validateMenuItem(menuItem)
        }
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
            panel.nameFieldStringValue = lump.name.sanitizedLumpFile() + ".lmp"
            panel.beginSheetModal(for: mainWindow) { response in
                if response == .OK {
                    // this is not an operation
                    guard let url = panel.url else {
                        return
                    }

                    do {
                        try lump.write(url: url)
                    } catch let error {
                        let alert = NSAlert()
                        alert.alertStyle = .warning
                        alert.messageText = "Couldn't export lump '\(lump.name)' to '\(url.path)'"
                        alert.informativeText = error.localizedDescription
                        alert.beginSheetModal(for: self.mainWindow, completionHandler: nil)
                        self.reportStatus(text: "Failed exporting 1 lump. \(error.localizedDescription)")
                        return
                    }

                    self.reportStatus(text: "Exported 1 lump", finderLinkURL: url.deletingLastPathComponent())
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
                    let filenames = lumps.map { $0.name.sanitizedLumpFile() + ".lmp" }
                    let overwritten = filenames.compactMap { filename -> String? in
                        let url = url.appendingPathComponent(filename)
                        return FileManager.default.fileExists(atPath: url.path) ? filename : nil
                    }

                    ///
                    /// Nested function, needed because of make-sure alert
                    ///
                    func doExport() {
                        var failures = [String]()
                        var failureMessage: String? = nil
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
                            do {
                                try lump.write(url: lumpURL)
                            } catch let error {
                                failures.append(lump.name)
                                if failureMessage == nil {
                                    failureMessage = error.localizedDescription
                                }
                            }
                        }

                        if !failures.isEmpty {
                            let alert = NSAlert()
                            alert.alertStyle = .warning
                            alert.messageText = "Failed exporting the following " + countedWord(singular: "lump", plural: "lumps", count: failures.count) + " to '\(url.path)'"
                            alert.informativeText = stringEnumeration(array: failures, maxCount: 20, completionPunctuation: ".") + (failureMessage != nil ? "\n\n" + failureMessage! : "")
                            alert.beginSheetModal(for: self.mainWindow, completionHandler: nil)

                            let lumpDisplay = countedWord(singular: "lump", plural: "lumps", count: lumps.count - failures.count)
                            let failedDisplay = countedWord(singular: "lump", plural: "lumps", count: failures.count)
                            self.reportStatus(text: "Exported \(lumpDisplay), failed \(failedDisplay)", finderLinkURL: url)
                        } else {
                            self.reportStatus(text: "Exported \(countedWord(singular: "lump", plural: "lumps", count: lumps.count))",
                                              finderLinkURL: url)
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

    @IBAction func showInFinderClicked(_ sender: Any?) {
        guard let url = (sender as? ClickableLabel)?.info as? URL else {
            return
        }
        NSWorkspace.shared.open(url)
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
            let saneName = lump.name.sanitizedLumpFile()
            var url = tempClipboardPathURL.appendingPathComponent(saneName + ".lmp")
            if let numRepeats = repeats[url] {
                repeats[url] = numRepeats + 1
                url = tempClipboardPathURL.appendingPathComponent("\(saneName) \(numRepeats).lmp")
            } else {
                repeats[url] = 1
            }
            let item = LumpClipboardProvider.Item()
            item.lump = lump
            item.url = url
            let provider = LumpClipboardProvider()
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
    /// Focus on the find box
    ///
    @IBAction func performFindPanelAction(_ sender: Any?) {
        guard let item = sender as? NSMenuItem,
            let action = NSFindPanelAction(rawValue: UInt(item.tag)) else
        {
            return
        }
        switch action {
        case .showFindPanel, NSFindPanelAction(rawValue: 12):   // also support find-and-replace, even if it's just find
            lumpFilterBox.becomeFirstResponder()
        case .setFindString:
            lumpFilterBox.stringValue = wad.lumps[lumpListDelegate.defiltered(index: lumpList.selectedRow)].name
            let board = NSPasteboard(name: .find)
            board.clearContents()
            let string = lumpFilterBox.stringValue
            board.writeObjects([string as NSString])
            lumpFilterBox.becomeFirstResponder()
            searchBoxUpdated(lumpFilterBox)
        default:
            return
        }
    }

    // MARK: User interface actions

    ///
    /// User is searching
    ///
    var previousSearchString = ""
    @IBAction func searchBoxUpdated(_ sender: Any?) {
        let currentString = lumpFilterBox.stringValue
        let realRow: Int?

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
