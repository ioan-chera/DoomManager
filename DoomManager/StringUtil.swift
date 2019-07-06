//
//  StringUtil.swift
//  DoomManager
//
//  Created by ioan on 30/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

///
/// Enumerates the items in an array nicely. Don't use Oxford comma.
///
func stringEnumeration(array: [String], maxCount: Int, completionPunctuation: String = "") -> String {
    if array.count == 0 {
        return ""
    }
    if array.count == 1 {
        return array[0]
    }

    if array.count > maxCount {
        return array[0..<maxCount].joined(separator: ", ") + "…"
    }

    return array.dropLast().joined(separator: ", ") + " and " + array.last! + completionPunctuation
}

///
/// Nicely counted word
///
func countedWord(singular: String, plural: String, count: Int) -> String {
    let countText = String(count)
    return count == 1 ? "1 " + singular : countText + " " + plural
}

///
/// Replaces all occurences of some characters from set
///
extension String {
    ///
    /// Enumerating all characters from a set, replaces them with string
    ///
    func replacingAllCharacters(fromSet set: String, with string: String) -> String {
        var result = self
        for character in set {
            result = result.replacingOccurrences(of: String(character), with: string)
        }
        return result
    }

    ///
    /// Sanitizes for lump saving
    ///
    func sanitizedLumpFile() -> String {
        return replacingOccurrences(of: "\\", with: "^").replacingOccurrences(of: "/", with: ":")
    }
}
