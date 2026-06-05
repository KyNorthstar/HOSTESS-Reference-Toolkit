//
//  HostessObjectStateTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessObjectState")
struct HostessObjectStateTests {
    
    /// The raw values are part of the serialized contract: anything that's
    /// already been written to a shelf will decode `"open"` back to `.open`,
    /// so a casual rename of the case must not also rename the raw value.
    @Test("Raw values are the exact lowercase case names",
          arguments: zip([HostessObjectState.open, .complete, .dropped],
                         ["open",                   "complete", "dropped"]))
    func rawValuesAreLowercaseCaseNames(state: HostessObjectState, expectedRawValue: String) {
        #expect(state.rawValue == expectedRawValue)
    }
    
    
    @Test("Every case survives a JSON round-trip",
          arguments: [HostessObjectState.open, .complete, .dropped])
    func codableRoundTrip(state: HostessObjectState) throws {
        // Wrap in a container so we don't depend on top-level fragment support.
        struct Wrapper: Codable { var value: HostessObjectState }
        
        let encoded = try JSONEncoder().encode(Wrapper(value: state))
        let decoded = try JSONDecoder().decode(Wrapper.self, from: encoded)
        
        #expect(decoded.value == state)
    }
    
    
    /// String-backed enums emit the bare raw value as JSON. Locking this
    /// representation down means future migrations can't quietly change
    /// the on-disk format.
    @Test("Encodes as the bare raw-value string",
          arguments: zip([HostessObjectState.open, .complete, .dropped],
                         ["\"open\"",              "\"complete\"", "\"dropped\""]))
    func encodesAsBareString(state: HostessObjectState, expectedJSON: String) throws {
        let encoded = try JSONEncoder().encode(state)
        #expect(String(data: encoded, encoding: .utf8) == expectedJSON)
    }
}
