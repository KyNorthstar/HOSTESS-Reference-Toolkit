//
//  HostessObject.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

@preconcurrency import SemVer
import SHELF



/// An object in a HOSTESS object graph. The `payload` is arbitrary, hinted at by the `type` field.
public struct HostessObject<Payload: HostessPayload> {
    /// The format version of this HOSTESS object.
    ///
    /// This determines whether version-dependent fields and contents are compatible with arbitrary encoded data. If the version of encoded data is incompatible with this, then the encoded data must be migrated or this decoder must be udpated
    public let version: SemVer
    
    /// This identifies this HOSTESS object universally, so it can be used without context
    public let id: ShelfId
    
    /// A hint to parsing: what type of HOSTESS object is this?
    public let type: HostessObjectKind
    
    /// Arbitrary data, like a task or tasklist
    public var payload: Payload
    
    
    public init(version: SemVer, id: ShelfId, type: HostessObjectKind, payload: Payload) {
        self.version = version
        self.id = id
        self.type = type
        self.payload = payload
    }
}



// MARK: - Compatibility tools

public extension HostessObject {
    static var currentVersion: SemVer { SemVer(0,1,0) }
}



// MARK: - Subtypes

/// Describes various types of HOSTESS object.
///
/// The format (e.g. Swift type) of `payload` fields in ``HostessObject``s should align to this type
public enum HostessObjectKind: String {
    
    /// The prototypical HOSTESS object: a single task
    case task
    
    /// A collection of related tasks.
    ///
    /// Projects, shopping lists, calendars, mailboxes, etc.
    case tasklist
}



public extension HostessObject {
    typealias Kind = HostessObjectKind
}



/// The payload of every HOSTESS object should conform to this
public protocol HostessPayload: AnyHostessType & Codable {}



// MARK: - conformances

extension HostessObject: AnyHostessType {}
extension HostessObject: ShelfData {}

extension HostessObjectKind: AnyHostessType {}
extension HostessObjectKind: Codable {}



extension HostessObject: Encodable {
    enum CodingKeys: String, AnyHostessType, CodingKey {
        case version = "_v"
        case payload = "_c"
        case type    = "t"
        case id      = "id"
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        var container: KeyedEncodingContainer<CodingKeys> = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.payload, forKey: .payload)
        
        
        // 0.1.0-specific data
        
        try container.encode(self.type, forKey: .type)
    }
}



extension HostessObject: Decodable {
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(SemVer.self, forKey: .version)
        
        guard version <= Self.currentVersion else {
            throw DecodeError.incompatibleVersion
        }
        
        self.id = try container.decode(ShelfId.self, forKey: .id)
        self.payload = try container.decode(Payload.self, forKey: .payload)
        
        
        // 0.1.0-specific data
        
        self.type = try container.decode(HostessObjectKind.self, forKey: .type)
    }
    
    
    
    public enum DecodeError: AnyHostessType, Error {
        case incompatibleVersion
    }
}
