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

extension URL {
    ///
    /// Safe rename of file to prevent overwriting
    ///
    func numberRenamed() -> URL {
        var suffix = 1
        let dirname = deletingPathExtension().deletingLastPathComponent()
        let title = deletingPathExtension().lastPathComponent
        var modified = self
        while FileManager.default.fileExists(atPath: modified.path) && suffix < 1000 {
            modified = dirname.appendingPathComponent("\(title) \(suffix)").appendingPathExtension(pathExtension)
            suffix += 1
        }
        return modified
    }

    ///
    /// Does some changes to file name:
    /// - replaces \ with ^ (because they're used in some states and Windows doesn't allow \)
    /// - replaces / and : with -
    ///
    func sanitizedLump() -> URL {
        let path = lastPathComponent.sanitizedLumpFile()
        return deletingLastPathComponent().appendingPathComponent(path)
    }
}
