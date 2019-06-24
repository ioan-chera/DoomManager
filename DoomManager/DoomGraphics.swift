//
//  DoomGraphics.swift
//  DoomManager
//
//  Created by ioan on 23/06/2019.
//  Copyright © 2019 Ioan Chera. All rights reserved.
//

import Foundation

///
/// Doom non-flat graphics
///
class DoomGraphics {

    struct Post {
        let yOffset: Int
        let data: [UInt8]
    }

    private let columns: [[Post]]
    private let height: Int
    private let leftOffset: Int
    private let topOffset: Int

    ///
    /// Tries to read from a lump
    ///
    init?(data: [UInt8]) {
        if data.count < 8 {
            return nil
        }
        let reader = DataReader(data)
        let width = Int(reader.short())
        height = Int(reader.short())
        leftOffset = Int(reader.short())
        topOffset = Int(reader.short())
        if data.count < 8 + 4 * width {
            return nil
        }
        let columnOffsets = reader.uint32Array(size: width)
        for offset in columnOffsets {
            if offset + 1 > data.count {
                return nil
            }
        }

        var columns = [[Post]]()

        for offset in columnOffsets {
            var posts = [Post]()
            // Read posts
            reader.seek(position: Int(offset))

            while true {

                if reader.pos >= data.count {
                    return nil
                }

                let yOffset = reader.byte()
                if yOffset == 255 {
                    break
                }
                if reader.pos + 3 > data.count {
                    return nil
                }
                let length = reader.byte()
                if reader.pos + 2 + Int(length) > data.count {
                    return nil
                }
                reader.byte()   // skip 0 padding

                let post = Post(yOffset: Int(yOffset), data: reader.byteArray(size: Int(length)))
                posts.append(post)

                reader.byte()   // skip trailing padding
            }

            columns.append(posts)
        }
        self.columns = columns
    }
}
