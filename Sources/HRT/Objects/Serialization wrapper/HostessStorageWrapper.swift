//
//  HostessStorageWrapper.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

@preconcurrency import SemVer
import SHELF



private let currentFormatVersion = SemVer(0,1,0)



/// Wraps HOSTESS objects to be stored in the object store
public struct HostessStorageWrapper<Payload: HostessPayload> {
    
    /// The format version of this HOSTESS object.
    ///
    /// This determines whether version-dependent fields and contents are compatible with arbitrary encoded data. If the version of encoded data is incompatible with this, then the encoded data must be migrated or this decoder must be udpated
    public let version: SemVer
    
    /// This identifies this HOSTESS object universally, so it can be used without context
    public let id: ShelfId
    
    /// A hint to parsing: what type of HOSTESS object is this?
    public let type: HostessObjectKind
    
    /// Arbitrary HOSTESS data, like a task or tasklist
    public var payload: Payload
    
    
    public init(version: SemVer = currentVersion, id: ShelfId, type: HostessObjectKind, payload: Payload) {
        self.version = version
        self.id = id
        self.type = type
        self.payload = payload
    }
}



public extension HostessStorageWrapper
    where Payload: IdealPayload
{
    /// Wraps the given payload in this object, ready to be persisted to the store
    ///
    /// - Parameter payload: The HOSTESS object to wrap
    init(wrapping payload: Payload) {
        self.init(id: payload.id, type: payload.kind, payload: payload)
    }
}



// MARK: - Compatibility tools

public extension HostessStorageWrapper {
    static var currentVersion: SemVer { currentFormatVersion }
}



// MARK: - Subtypes

/// Describes various types of HOSTESS object.
/// 
/// The format (e.g. Swift type) of `payload` fields in ``HostessObject``s should align to this type.
public enum HostessObjectKind {
    
    /// The prototypical HOSTESS object: a single task
    ///
    /// A todo, a grocery, an appointment, an email, etc.
    case task
    
    /// A collection of related tasks.
    ///
    /// Projects, shopping lists, calendars, mailboxes, etc.
    case tasklist
    
    /// A HOSTESS tag, which can be applied to many other kinds of HOSTESS objects
    case tag
    
    
    /// Any arbitrary object, stored within HOSTESS
    case custom(RawValue)
    
    
    /// All the non-custom HOSTESS object kinds
    static let reservedCases: [Self] = [.task, .tasklist, .tag]
}



extension HostessObjectKind: RawRepresentable {
    
    
    public init(rawValue: RawValue) {
        switch rawValue {
        case Self.task.rawValue:     self = .task
        case Self.tasklist.rawValue: self = .tasklist
        case Self.tag.rawValue:      self = .tag
        default:                     self = .custom(rawValue)
        }
    }
    
    
    public var rawValue: RawValue {
        switch self {
        case .task:                 return RawValue(hostessReservedType: "task")
        case .tasklist:             return RawValue(hostessReservedType: "tasklist")
        case .tag:                  return RawValue(hostessReservedType: "tag")
        case .custom(let rawValue): return rawValue
        }
    }
    
    
    
    /// The raw value of a HOSTESS object kind.
    ///
    /// - Attention: The fields of this raw value MUST be in ASCII alphanumerics. If they contain any other characters, this will refuse to initialize.
    public struct RawValue: Equatable, Sendable {
        
        /// The domain of the type.
        ///
        /// HOSTESS reserved system objects have an empty domain. All others MUST be a traditional reverse-domain-name-formatted ASCII alphanumeric dot-separated string, like `"org.kindness.app"`, and SHOULD be all-lowercase.
        public let domain: String
        
        /// The type name
        ///
        /// This MUST be ASCII alphanumeric, like `"Chart"`. It SHOULD be capitalized-camel-case.
        public let type: String
        
        
        /// Initialize a custom type's raw value
        ///
        /// - Parameters:
        ///   - domain: The domain of the type.
        ///             This MUST be a traditional reverse-domain-name-formatted ASCII alphanumeric dot-separated string, like `"org.kindness.app"`. It SHOULD be all-lowercase.
        ///
        ///   - type:   The type name itself.
        ///             This MUST be ASCII alphanumeric, like `"Chart"`. It SHOULD be capitalized-camel-case.
        public init?(domain: String, type: String) {
            let domainRegex = /^[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)+$/
            let typeRegex = /^[a-zA-Z0-9]+$/
            
            guard nil != (try? domainRegex.firstMatch(in: domain)),
                  nil != (try? typeRegex.firstMatch(in: type))
            else {
                return nil
            }
            
            self.domain = domain
            self.type = type
        }
        
        
        fileprivate init(hostessReservedType: String) {
            self.domain = ""
            self.type = hostessReservedType
        }
    }
}



extension HostessObjectKind.RawValue: CustomStringConvertible {
    public var description: String {
        "\(domain).\(type)"
    }
}



extension HostessObjectKind.RawValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container: SingleValueEncodingContainer = encoder.singleValueContainer()
        try container.encode(description)
    }
}



extension HostessObjectKind.RawValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container: SingleValueDecodingContainer = try decoder.singleValueContainer()
        
        let rawValueString: String = try container.decode(String.self)
        
        for reserved in HostessObjectKind.reservedCases {
            if reserved.rawValue.description == rawValueString {
                self = reserved.rawValue
                return
            }
        }
        
        let regex = /^(?<domain>[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)+)\.(?<type>[a-zA-Z0-9]+)$/
        
        guard let match = try regex.firstMatch(in: rawValueString)?.output else {
            throw DecodingError.dataCorrupted(DecodingError.Context.init(codingPath: [], debugDescription: #"Custom HOSTESS object types MUST be in the format /^[a-zA-Z0-9]+(?:\.[a-zA-Z0-9]+)+[a-zA-Z0-9]+$/ – the given value was "\#(rawValueString)""#))
        }
        
        self.domain = String(match.domain)
        self.type = String(match.type)
    }
}



public extension HostessStorageWrapper {
    typealias Kind = HostessObjectKind
}



// MARK: - conformances

extension HostessStorageWrapper: AnyHostessType {}
extension HostessStorageWrapper: ShelfData {}

extension HostessObjectKind: AnyHostessType {}



extension HostessObjectKind: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}



extension HostessObjectKind: Decodable {
    public init(from decoder: any Decoder) throws {
        self.init(rawValue: try decoder
            .singleValueContainer()
            .decode(RawValue.self)
        )
    }
}



extension HostessStorageWrapper: Encodable {
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



extension HostessStorageWrapper: Decodable {
    public init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(SemVer.self, forKey: .version)
        
        guard version <= currentFormatVersion else {
            throw DecodeError.incompatibleVersion(found: version)
        }
        
        self.id = try container.decode(ShelfId.self, forKey: .id)
        self.payload = try container.decode(Payload.self, forKey: .payload)
        
        
        // 0.1.0-specific data
        
        self.type = try container.decode(HostessObjectKind.self, forKey: .type)
    }
    
    
    
    public enum DecodeError: AnyHostessType, LocalizedError {
        case incompatibleVersion(found: SemVer)
        
        
        public var errorDescription: String? {
            switch self {
            case .incompatibleVersion(found: let found):
                return """
                    The decoded HOSTESS object was written with an incompatible version of the HOSTESS format: \(found).
                    This is version \(currentFormatVersion).
                    Please upgrade HRT to use the current version of the HOSTESS format, or file a bug report if this is the latest version of HRT.
                    """
            }
        }
    }
}
