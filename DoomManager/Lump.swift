/*
 DoomManager
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
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import AppKit
import Foundation

///
/// Wad lump. Contains the actual data and the name.
///
class Lump: NSObject, NSSecureCoding, NSPasteboardWriting, NSPasteboardReading
{
    private var _nameBytes: [UInt8]  // byte array up to 8 values
    var data: [UInt8]

    static let uti = "doom.classic.lump"

    var nameBytes: [UInt8] {
        get {
            return self._nameBytes
        }
        set(value) {
            self._nameBytes = Lump.truncateZero(value)
        }
    }

    var name: String {
        get {
            return Lump.nameAsString(self.nameBytes)
        }
        set(value) {
            var string = value.uppercased()
            if value.count > 8 {
                string = String(string[..<value.index(value.startIndex, offsetBy: 8)])
                while string.count > 1 && string.utf8.count > 8 {
                    string = String(string[..<string.index(before: string.endIndex)])
                }
            }
            self.nameBytes = Array(string.utf8.prefix(8))
        }
    }

    static func nameAsString(_ nameBytes: [UInt8]) -> String {
        let string = String(bytes: nameBytes, encoding: String.Encoding.utf8) ?? ""
        return string.uppercased()
    }

    static func truncateZero(_ bytes: [UInt8]) -> [UInt8] {
        var result: [UInt8] = []
        for a in bytes {
            if a == 0 {
                return result
            }
            result.append(a)   // preserve all values up to the
            // null terminator
        }
        return result
    }

    init(name: String)
    {
        self._nameBytes = []
        self.data = []
        super.init()
        self.name = name
    }

    init(name: String, data: Data)
    {
        self._nameBytes = []
        self.data = data.asArray()
        super.init()
        self.name = name
    }

    init(nameData: Data, data: Data) {
        self._nameBytes = []
        self.data = data.asArray()
        super.init()
        self.nameBytes = nameData.asArray()
    }

    ///
    /// Convenience from URL
    ///
    convenience init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        self.init(name: url.deletingPathExtension().lastPathComponent, data: data)
    }

    ///
    /// Write lump to a file (as a URL)
    ///
    func write(url: URL) throws {
        let data = Data(bytes: self.data, count: self.data.count)
        try data.write(to: url)
    }

    ///
    /// Info for copying
    ///
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [.init("doom.classic.lump"), .string]
    }

    ///
    /// Required properties for writing to clipboard
    ///
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if type.rawValue == Lump.uti {
            return try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        }
        if type == .string {
            return name
        }
        return nil
    }

    ///
    /// Info for pasting
    ///
    static func readableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [.init(Lump.uti), .fileURL]
    }

    ///
    /// Options for reading
    ///
    static func readingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.ReadingOptions {
        if type.rawValue == Lump.uti {
            return .asKeyedArchive
        } else if type == .fileURL {
            return NSURL.readingOptions(forType: type, pasteboard: pasteboard)
        }
        return .init()
    }

    ///
    /// Given properties, now what?
    ///
    required convenience init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        if type == .fileURL {
            guard let nsurl = NSURL(pasteboardPropertyList: propertyList, ofType: type) else {
                return nil
            }
            self.init(url: nsurl as URL)
        } else {
            return nil
        }
    }

    ///
    /// NSCoding stuff
    ///
    func encode(with aCoder: NSCoder) {
        let nameBytesData = NSData(bytes: _nameBytes, length: _nameBytes.count)
        let dataData = NSData(bytes: data, length: data.count)
        aCoder.encode(nameBytesData, forKey: "nameBytes")
        aCoder.encode(dataData, forKey: "data")
    }

    ///
    /// NSCoding stuff
    ///
    required init?(coder aDecoder: NSCoder) {
        guard let nameBytesData = aDecoder.decodeObject(of: [NSData.self], forKey: "nameBytes") as? Data,
            let dataData = aDecoder.decodeObject(of: [NSData.self], forKey: "data") as? Data else
        {
            return nil
        }
        _nameBytes = nameBytesData.asArray()
        data = dataData.asArray()
    }

    ///
    /// Required by the pasteboard. Means using "decodeObject" with class specified.
    ///
    static var supportsSecureCoding: Bool {
        return true
    }
}
