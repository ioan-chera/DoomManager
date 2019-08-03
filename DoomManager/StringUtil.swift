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
