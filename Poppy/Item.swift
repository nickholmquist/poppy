//
//  Item.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/6/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
