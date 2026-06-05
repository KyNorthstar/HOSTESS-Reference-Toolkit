//
//  HostessObjectKindTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessObjectKind.RawValue construction")
struct HostessObjectKindRawValueConstructionTests {
    
    @Test("Accepts a valid reverse-DNS domain with an alphanumeric type",
          arguments: [
            (domain: "com.example",         type: "Chart"),
            (domain: "org.kindness.app",    type: "Mood"),
            (domain: "a.b",                 type: "X"),
            (domain: "ABC.DEF.GHI",         type: "Foo123"),
            (domain: "a1.b2.c3",            type: "T9"),
          ])
    func acceptsValidInputs(domain: String, type: String) throws {
        let raw = try #require(
            HostessObjectKind.RawValue(domain: domain, type: type),
            "(\(domain), \(type)) should be a valid custom raw value"
        )
        #expect(raw.domain == domain)
        #expect(raw.type == type)
    }
    
    
    @Test("Rejects domains that aren't reverse-DNS or aren't ASCII alphanumeric",
          arguments: [
            (domain: "",                 type: "Foo"),     // empty
            (domain: "example",          type: "Foo"),     // no dot
            (domain: "com.exämple",      type: "Foo"),     // non-ASCII
            (domain: "com..example",     type: "Foo"),     // empty segment
            (domain: ".com.example",     type: "Foo"),     // leading dot
            (domain: "com.example.",     type: "Foo"),     // trailing dot
            (domain: "com example",      type: "Foo"),     // whitespace
            (domain: "com-example.org",  type: "Foo"),     // hyphen
          ])
    func rejectsInvalidDomains(domain: String, type: String) {
        #expect(
            HostessObjectKind.RawValue(domain: domain, type: type) == nil,
            "Domain \"\(domain)\" should be rejected as invalid"
        )
    }
    
    
    @Test("Rejects types that aren't pure ASCII alphanumeric",
          arguments: [
            (domain: "com.example", type: ""),           // empty
            (domain: "com.example", type: "Foo.Bar"),    // contains dot
            (domain: "com.example", type: "Foo Bar"),    // whitespace
            (domain: "com.example", type: "Foo-Bar"),    // hyphen
            (domain: "com.example", type: "Föo"),        // non-ASCII
          ])
    func rejectsInvalidTypes(domain: String, type: String) {
        #expect(
            HostessObjectKind.RawValue(domain: domain, type: type) == nil,
            "Type \"\(type)\" should be rejected as invalid"
        )
    }
    
    
    @Test("description joins domain and type with a single dot")
    func descriptionFormat() throws {
        let raw = try #require(HostessObjectKind.RawValue(domain: "com.example", type: "Chart"))
        #expect(raw.description == "com.example.Chart")
    }
}



@Suite("HostessObjectKind reserved cases")
struct HostessObjectKindReservedCaseTests {
    
    @Test("Each reserved case has its bare type name as its raw-value description",
          arguments: zip(
            [HostessObjectKind.task, .tasklist, .tag],
            [".task",                 ".tasklist", ".tag"]
          ))
    func reservedDescriptions(kind: HostessObjectKind, expectedDescription: String) {
        // Reserved kinds carry an empty domain, so the description starts with a dot.
        // This pins down the on-disk representation of the three system kinds.
        #expect(kind.rawValue.description == expectedDescription)
    }
    
    
    /// `init(rawValue:)` should funnel reserved descriptions back to their reserved
    /// case rather than wrapping them in `.custom`. Otherwise equality-by-rawValue
    /// could lie about which case is which.
    @Test("init(rawValue:) recovers the reserved case for each reserved raw value",
          arguments: [HostessObjectKind.task, .tasklist, .tag])
    func reservedInitRoundTrip(reserved: HostessObjectKind) {
        let reconstructed = HostessObjectKind(rawValue: reserved.rawValue)
        
        // We can't rely on Equatable on HostessObjectKind itself, so check shape and value.
        switch (reserved, reconstructed) {
        case (.task,     .task),
             (.tasklist, .tasklist),
             (.tag,      .tag):
            break // OK
            
        case (_, .custom(let raw)):
            Issue.record("""
                Reserved kind \(reserved.rawValue.description) was decoded as \
                .custom(\(raw.description)) instead of its reserved case
                """)
            
        default:
            Issue.record("Reserved kind \(reserved.rawValue.description) decoded to the wrong case")
        }
    }
}



@Suite("HostessObjectKind Codable")
struct HostessObjectKindCodableTests {
    
    @Test("Each reserved case round-trips through JSON",
          arguments: [HostessObjectKind.task, .tasklist, .tag])
    func reservedRoundTrip(reserved: HostessObjectKind) throws {
        let encoded = try JSONEncoder().encode(reserved)
        let decoded = try JSONDecoder().decode(HostessObjectKind.self, from: encoded)
        
        // Match by case shape — HostessObjectKind isn't directly Equatable.
        switch (reserved, decoded) {
        case (.task,     .task),
             (.tasklist, .tasklist),
             (.tag,      .tag):
            break // OK
        default:
            Issue.record("""
                Reserved kind \(reserved.rawValue.description) did not round-trip — \
                decoded as \(decoded.rawValue.description)
                """)
        }
    }
    
    
    /// This test encodes the *intended* contract: any custom raw value should
    /// round-trip through JSON and arrive back with the same `domain` and `type`.
    ///
    /// At the time of writing, the decoder's regex is missing a literal `\.`
    /// between the `domain` and `type` capture groups, so `com.example` + `Chart`
    /// decodes back as `domain == "com.example.Char"`, `type == "t"`. When that
    /// regex is fixed, this test should pass.
    @Test("Custom kinds round-trip through JSON preserving domain and type",
          arguments: [
            (domain: "com.example",      type: "Chart"),
            (domain: "org.kindness.app", type: "Mood"),
            (domain: "a.b",              type: "X"),
            (domain: "a.b.c.d.e",        type: "Foo"),
          ])
    func customRoundTrip(domain: String, type: String) throws {
        let originalRaw = try #require(
            HostessObjectKind.RawValue(domain: domain, type: type),
            "Test input (\(domain), \(type)) should construct a valid raw value"
        )
        let original = HostessObjectKind.custom(originalRaw)
        
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HostessObjectKind.self, from: encoded)
        
        #expect(
            decoded.rawValue == original.rawValue,
            """
            A custom kind should decode back to its original domain and type, but:
              original: domain="\(original.rawValue.domain)", type="\(original.rawValue.type)"
              decoded:  domain="\(decoded.rawValue.domain)",  type="\(decoded.rawValue.type)"
            """
        )
    }
    
    
    @Test("Decoding fails for strings that aren't a valid custom or reserved raw value")
    func decodingFailsForGarbage() throws {
        // A bare word doesn't match the regex (no dot) and isn't reserved.
        struct Wrapper: Codable { var value: HostessObjectKind }
        let badJSON = Data(#"{"value":"notavalidkind"}"#.utf8)
        
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Wrapper.self, from: badJSON)
        }
    }
}
