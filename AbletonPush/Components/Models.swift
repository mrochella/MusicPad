//
//  Models.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import Foundation
import SwiftData


struct SoundPad: Identifiable, Equatable {
    let id: UUID
    var name: String
    var fileURL: URL
    var isDefault: Bool
    
    init(name: String, fileURL: URL, isDefault: Bool) {
        self.id = UUID()
        self.name = name
        self.fileURL = fileURL
        self.isDefault = isDefault
    }
    
    init(id: UUID, name: String, fileURL: URL, isDefault: Bool) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.isDefault = isDefault
    }

    static func == (lhs: SoundPad, rhs: SoundPad) -> Bool {
        return lhs.id == rhs.id
    }
}

@Model
class SoundPadEntity {
    var id: UUID
    var name: String
    var filePath: String
    var isDefault: Bool
    
    init(name: String = "", filePath: String = "", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.isDefault = isDefault
    }
    
    var asSoundPad: SoundPad {
        SoundPad(id: id, name: name, fileURL: URL(fileURLWithPath: filePath), isDefault: isDefault)
    }
}

struct DelayItem: Identifiable, Equatable {
    let id = UUID()
    var duration: Double // in seconds
    
    static func == (lhs: DelayItem, rhs: DelayItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct PadInfo: Codable {
    let name: String
    let path: String
} 
