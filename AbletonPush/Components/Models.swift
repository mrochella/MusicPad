//
//  Models.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import Foundation

struct SoundPad: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var fileURL: URL
    var isDefault: Bool

    static func == (lhs: SoundPad, rhs: SoundPad) -> Bool {
        return lhs.id == rhs.id
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