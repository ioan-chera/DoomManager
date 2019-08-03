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
