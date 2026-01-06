//
//  HostessObject.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

@preconcurrency import SemVer
import SHELF



/// An object in a HOSTESS object graph. The `content` is arbitrary, hinted at by the `type` field.
public struct HostessObject<Content: Codable> {
    let version: SemVer
    let type: HostessObjectType
    var content: Content
}



// MARK: - Compatibility tools

public extension HostessObject {
    static var currentVersion: SemVer { SemVer(0,1,0) }
}



// MARK: - Subtypes

/// Describes various types of HOSTESS object.
///
/// The format (e.g. Swift type) of `content` fields in ``HostessObject``s should align to this type
public enum HostessObjectType: String, Codable {
    
    /// The prototypical HOSTESS object: a single task
    case task
}



// MARK: - Conformances

extension HostessObject: Encodable {
    enum CodingKeys: String, CodingKey {
        case version = "_v"
        case content = "_c"
        case type    = "t"
        case id      = "id"
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.version, forKey: CodingKeys.version)
        try container.encode(self.content, forKey: CodingKeys.content)
        try container.encode(self.type, forKey: CodingKeys.type)
    }
}



extension HostessObject: Decodable {
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(SemVer.self, forKey: CodingKeys.version)
        
        guard version <= Self.currentVersion else {
            throw DecodeError.incompatibleVersion
        }
        
        self.content = try container.decode(Content.self, forKey: CodingKeys.content)
        
        // 0.1.0-specific data
        self.type = try container.decode(HostessObjectType.self, forKey: CodingKeys.type)
    }
    
    
    
    public enum DecodeError: Error {
        case incompatibleVersion
    }
}
