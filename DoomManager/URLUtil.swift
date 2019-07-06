//
//  URLUtil.swift
//  DoomManager
//
//  Created by ioan on 04/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

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
