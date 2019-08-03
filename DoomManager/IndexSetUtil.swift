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
/// class extensions
///
extension IndexSet {
    ///
    /// Gets a decremented index set for a given minimum
    ///
    func decremented(minimum: Int) -> IndexSet {
        let numbers = Array(self)
        var newSet = Set<Int>()
        for number in numbers {
            if number <= minimum || newSet.contains(number - 1) {
                newSet.insert(number)
                continue
            }
            newSet.insert(number - 1)
        }
        return IndexSet(newSet)
    }

    ///
    /// Gets an incremented index set for a given maximum
    ///
    func incremented(maximum: Int) -> IndexSet {
        let numbers = Array(self).reversed()
        var newSet = Set<Int>()
        for number in numbers {
            if number >= maximum || newSet.contains(number + 1) {
                newSet.insert(number)
                continue
            }
            newSet.insert(number + 1)
        }
        return IndexSet(newSet)
    }
}
