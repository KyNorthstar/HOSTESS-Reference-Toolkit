//
//  HostessTagTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessTag")
struct HostessTagTests {
    
    @Test("Initializer populates the supplied id and label")
    func initializerPopulatesFields() {
        let id = ShelfId()
        let tag = HostessTag(id: id, label: "urgent")
        
        #expect(tag.id == id)
        #expect(tag.label == "urgent")
    }
    
    
    @Test("Initializer accepts a String label literal")
    func acceptsStringLiteralLabel() {
        // Belt-and-suspenders: explicit cast to ensure we exercise the
        // intended (String) overload rather than any future
        // ExpressibleByStringLiteral path that might be added.
        let tag = HostessTag(label: "groceries" as String)
        #expect(tag.label == "groceries")
    }
    
    
    @Test("Omitting the id auto-generates a fresh, unique one")
    func defaultIdIsUnique() {
        let a = HostessTag(label: "a")
        let b = HostessTag(label: "a") // same label, different identity
        
        #expect(a.id != b.id, "Two tags with the same label should still have distinct ids")
    }
    
    
    @Test("kind is always .tag, regardless of label")
    func kindIsAlwaysTag() {
        let tag = HostessTag(label: "anything")
        #expect(tag.kind.rawValue == HostessObjectKind.tag.rawValue)
    }
    
    
    @Test("label is mutable")
    func labelIsMutable() {
        var tag = HostessTag(label: "old")
        tag.label = "new"
        #expect(tag.label == "new")
    }
    
    
    /// Mutating one copy of a value-type tag must not affect the other —
    /// this confirms HostessTag preserves value semantics, which is a
    /// foundational property of the whole HOSTESS model layer.
    @Test("Mutating a copy doesn't affect the original")
    func valueSemantics() {
        let original = HostessTag(label: "original")
        var copy = original
        copy.label = "mutated"
        
        #expect(original.label == "original")
        #expect(copy.label == "mutated")
        #expect(copy.id == original.id, "Copying does not change identity")
    }
}
