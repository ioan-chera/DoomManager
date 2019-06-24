//
//  LumpAnalysis.swift
//  DoomManager
//
//  Created by ioan on 23/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

enum LumpType: String {
    case doomGraphics = "Graphics"
    case marker = "Marker"
    case text = "Text"
    case unknown = "Other"
}

///
/// Analyzes a lump type
///
func analyzeLumpType(_ lump: Lump) -> LumpType {

    if lump.data.count == 0 {
        return .marker
    }

    let doomGraphics = DoomGraphics(data: lump.data)
    if doomGraphics != nil {
        return .doomGraphics
    }
    return .unknown
}
