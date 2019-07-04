//
//  CommonPaths.swift
//  DoomManager
//
//  Created by ioan on 01/07/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

let tempClipboardPathURL = FileManager.default.temporaryDirectory.appendingPathComponent("pboard")

///
/// To be called at startup
///
func ensureDirs() throws {
    try FileManager.default.createDirectory(at: tempClipboardPathURL, withIntermediateDirectories: true, attributes: nil)
}
