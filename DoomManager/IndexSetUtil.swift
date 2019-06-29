//
//  IndexSetUtil.swift
//  DoomManager
//
//  Created by ioan on 29/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

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
            if number == minimum || newSet.contains(number - 1) {
                newSet.insert(number)
                continue
            }
            newSet.insert(number - 1)
        }
        return IndexSet(newSet)
    }
}
