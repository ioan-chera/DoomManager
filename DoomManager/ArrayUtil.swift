//
//  ArrayUtil.swift
//  DoomManager
//
//  Created by ioan on 30/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

func arrayObjects<T>(_ array: [T], indices: IndexSet) -> [T] {
    return (array as NSArray).objects(at: indices) as! [T]
}
