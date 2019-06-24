/*
 DoomManager
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
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/**
 Quick way to read data from a stream into useful variables.
 */
class DataReader {
    private let data: [UInt8]
    private(set) var pos = 0

    /**
     Initializes with an UInt8 array/
     */
    init(_ data: [UInt8]) {
        self.data = data
    }

    /**
     Reads a 16-bit value
     */
    @discardableResult
    func short(_ val: inout Int) -> DataReader {
        val = Int(Int16(data[pos]) + (Int16(data[pos + 1]) << 8))
        pos += 2
        return self
    }

    @discardableResult
    func short(_ val: inout Int16) -> DataReader {
        val = Int16(data[pos]) | (Int16(data[pos + 1]) << 8)
        pos += 2
        return self
    }

    @discardableResult
    func byte() -> UInt8 {
        let val = data[pos]
        pos += 1
        return val
    }

    func short() -> Int16 {
        let val = Int16(data[pos]) | (Int16(data[pos + 1]) << 8)
        pos += 2
        return val
    }

    func int32() -> Int32 {
        let val = Int32(data[pos]) | (Int32(data[pos + 1]) << 8) | (Int32(data[pos + 2]) << 16) | (Int32(data[pos + 3]) << 24)
        pos += 4
        return val
    }
    func uint32() -> UInt32 {
        let val = UInt32(data[pos]) | (UInt32(data[pos + 1]) << 8) | (UInt32(data[pos + 2]) << 16) | (UInt32(data[pos + 3]) << 24)
        pos += 4
        return val
    }

    func int32Array(size: Int) -> [Int32] {
        var result = [Int32]()
        for _ in 0..<size {
            result.append(int32())
        }
        return result
    }
    func uint32Array(size: Int) -> [UInt32] {
        var result = [UInt32]()
        for _ in 0..<size {
            result.append(uint32())
        }
        return result
    }

    func byteArray(size: Int) -> [UInt8] {
        var result = [UInt8]()
        for _ in 0..<size {
            result.append(byte())
        }
        return result
    }

    func seek(position: Int) {
        pos = position
    }

    /**
     Reads a lump name
     */
    @discardableResult
    func lumpName(_ val: inout [UInt8]) -> DataReader {
        val = Lump.truncateZero(Array(data[pos ..< pos + 8]))
        val.append(0)   // ensure null terminator
        pos += 8
        return self
    }

    func lumpName() -> [UInt8] {
        var result = [UInt8]()
        lumpName(&result)
        return result
    }
}
