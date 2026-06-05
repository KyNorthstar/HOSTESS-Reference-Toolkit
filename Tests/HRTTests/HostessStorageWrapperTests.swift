//
//  HostessStorageWrapperTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessStorageWrapper construction")
struct HostessStorageWrapperConstructionTests {
    
    @Test("init(wrapping:) inherits id and kind from the payload")
    func wrappingInheritsIdAndKind() {
        let id = ShelfId()
        let tag = HostessTag(id: id, label: "groceries")
        
        let wrapper = HostessStorageWrapper(wrapping: tag)
        
        #expect(wrapper.id == tag.id)
        #expect(wrapper.id == id)
        #expect(wrapper.type.rawValue == HostessObjectKind.tag.rawValue)
    }
    
    
    @Test("init(wrapping:) stamps the current format version")
    func wrappingUsesCurrentVersion() {
        let wrapper = HostessStorageWrapper(wrapping: HostessTag(label: "test"))
        
        #expect(wrapper.version == HostessStorageWrapper<HostessTag>.currentVersion)
    }
    
    
    @Test("currentVersion is consistent across payload types")
    func currentVersionIsConsistent() {
        // The format version describes the wrapper layout, not the payload —
        // it shouldn't drift based on which payload type the generic is bound to.
        #expect(
            HostessStorageWrapper<HostessTag>.currentVersion
            == HostessStorageWrapper<HostessTasklist>.currentVersion
        )
    }
}



@Suite("HostessStorageWrapper Codable")
struct HostessStorageWrapperCodableTests {
    
    @Test("A wrapped tag survives a JSON round-trip with all fields intact")
    func tagRoundTrip() throws {
        let original = HostessTag(label: "errands")
        let wrapper = HostessStorageWrapper(wrapping: original)
        
        let encoded = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(HostessStorageWrapper<HostessTag>.self, from: encoded)
        
        #expect(decoded.id == wrapper.id)
        #expect(decoded.version == wrapper.version)
        #expect(decoded.type.rawValue == wrapper.type.rawValue)
        #expect(decoded.payload.id == original.id)
        #expect(decoded.payload.label == original.label)
    }
    
    
    @Test("A wrapped tasklist with no subtasks survives a JSON round-trip")
    func tasklistRoundTrip() throws {
        let original = HostessTasklist(
            name: "Weekend chores",
            notes: AttributedString("Things to do before Monday"),
            tasks: []
        )
        let wrapper = HostessStorageWrapper(wrapping: original)
        
        let encoded = try JSONEncoder().encode(wrapper)
        let decoded = try JSONDecoder().decode(HostessStorageWrapper<HostessTasklist>.self, from: encoded)
        
        #expect(decoded.payload.id == original.id)
        #expect(decoded.payload.name == original.name)
        #expect(decoded.payload.notes == original.notes)
        #expect(decoded.payload.tasks.isEmpty)
        #expect(decoded.payload.state.rawValue == original.state.rawValue)
    }
    
    
    /// The JSON keys (`_v`, `_c`, `t`, `id`) are part of the on-disk wire format.
    /// Renaming them would invalidate every existing shelf, so they're worth
    /// pinning down explicitly.
    @Test("The encoded JSON uses the short on-disk key names")
    func encodingUsesShortKeys() throws {
        let wrapper = HostessStorageWrapper(wrapping: HostessTag(label: "test"))
        
        let encoded = try JSONEncoder().encode(wrapper)
        let json = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any],
            "Encoded wrapper should be a JSON object"
        )
        
        #expect(json.keys.contains("_v"),  "version key should be \"_v\"")
        #expect(json.keys.contains("_c"),  "payload key should be \"_c\"")
        #expect(json.keys.contains("t"),   "type key should be \"t\"")
        #expect(json.keys.contains("id"),  "id key should be \"id\"")
    }
    
    
    /// Forward-compat: data written by a future, breaking format version
    /// should refuse to decode rather than silently dropping new fields.
    @Test("Decoding throws .incompatibleVersion for a too-new format version")
    func futureVersionThrows() throws {
        // Hand-build a JSON document with a major-version bump.
        let id = ShelfId()
        let futureJSON = Data("""
            {
              "_v": "9.0.0",
              "_c": { "id": "\(id)", "label": "from-the-future" },
              "t":  ".tag",
              "id": "\(id)"
            }
            """.utf8)
        
        #expect(throws: HostessStorageWrapper<HostessTag>.DecodeError.self) {
            _ = try JSONDecoder().decode(HostessStorageWrapper<HostessTag>.self, from: futureJSON)
        }
    }
    
    
    /// The current version itself must always decode — otherwise the previous
    /// test could give a false positive for any reason.
    @Test("Decoding accepts data stamped at the current format version")
    func currentVersionIsAccepted() throws {
        let wrapper = HostessStorageWrapper(wrapping: HostessTag(label: "current"))
        let encoded = try JSONEncoder().encode(wrapper)
        
        // Should not throw.
        let decoded = try JSONDecoder().decode(HostessStorageWrapper<HostessTag>.self, from: encoded)
        #expect(decoded.payload.label == "current")
    }
}
