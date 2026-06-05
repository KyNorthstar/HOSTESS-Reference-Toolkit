//
//  HostessTaskTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



// MARK: - Helpers

/// A throwaway parent reference. Tests that don't care about the parent's
/// identity can use this to keep the call site clean.
private func makeStubParent() -> HostessTask.Parent {
    .init(id: ShelfId())
}



// MARK: - Tests

@Suite("HostessTask")
struct HostessTaskTests {
    
    @Test("Initializer populates the supplied fields")
    func initializerPopulatesFields() {
        let id = ShelfId()
        let parent = makeStubParent()
        let body = AttributedString("Clean the kitchen")
        
        let task = HostessTask(id: id, body: body, parent: parent)
        
        #expect(task.id == id)
        #expect(task.body == body)
        #expect(task.parent.id == parent.id)
    }
    
    
    @Test("Optional fields default to nil")
    func optionalFieldsDefaultToNil() {
        let task = HostessTask(body: AttributedString("test"), parent: makeStubParent())
        
        #expect(task.notes == nil)
        #expect(task.subtasks == nil)
        #expect(task.tags == nil)
        #expect(task.state == nil)
        #expect(task.completionPercentage == nil)
    }
    
    
    @Test("Omitting the id auto-generates a fresh, unique one")
    func defaultIdIsUnique() {
        let a = HostessTask(body: AttributedString("x"), parent: makeStubParent())
        let b = HostessTask(body: AttributedString("x"), parent: makeStubParent())
        
        #expect(a.id != b.id, "Two tasks with the same body should still have distinct ids")
    }
    
    
    @Test("kind is always .task")
    func kindIsAlwaysTask() {
        let task = HostessTask(body: AttributedString("x"), parent: makeStubParent())
        #expect(task.kind.rawValue == HostessObjectKind.task.rawValue)
    }
    
    
    @Test("Body, notes, state, and completionPercentage are all mutable")
    func fieldsAreMutable() {
        var task = HostessTask(body: AttributedString("before"), parent: makeStubParent())
        
        task.body = AttributedString("after")
        task.notes = AttributedString("extra context")
        task.state = .dropped
        task.completionPercentage = 0.5
        
        #expect(task.body == AttributedString("after"))
        #expect(task.notes == AttributedString("extra context"))
        #expect(task.state == .dropped)
        #expect(task.completionPercentage == 0.5)
    }
    
    
    /// The `completion` computed property is the user-facing way to set
    /// state and percentage together. Setting it should propagate to both
    /// underlying fields atomically.
    @Test("Setting completion updates both state and completionPercentage")
    func settingCompletionUpdatesBothFields() {
        var task = HostessTask(body: AttributedString("x"), parent: makeStubParent())
        
        task.completion = .complete
        #expect(task.state == .complete)
        #expect(task.completionPercentage == 1)
        
        task.completion = .inProgress(percentage: 0.25)
        #expect(task.state == .open)
        #expect(task.completionPercentage == 0.25)
        
        task.completion = .dropped
        #expect(task.state == .dropped)
        #expect(task.completionPercentage == nil)
        
        task.completion = .notStarted
        #expect(task.state == .open)
        #expect(task.completionPercentage == nil)
    }
    
    
    /// Reading the same `completion` value back after setting it is the
    /// most useful invariant: a UI that toggles checkboxes and rereads
    /// the model expects the value it just wrote.
    @Test("completion round-trips through the get/set property",
          arguments: [
            HostessTask.Completion.notStarted,
            .inProgress(percentage: 0.5),
            .complete,
            .dropped,
          ])
    func completionGetSetRoundTrip(initialCompletion: HostessTask.Completion) {
        var task = HostessTask(body: AttributedString("x"), parent: makeStubParent())
        task.completion = initialCompletion
        
        #expect(task.completion == initialCompletion)
    }
    
    
    /// Value semantics: mutating one task must not affect another, even
    /// when both started from the same source.
    @Test("Mutating a copied task doesn't affect the original")
    func valueSemantics() {
        let original = HostessTask(body: AttributedString("original"), parent: makeStubParent())
        var copy = original
        copy.body = AttributedString("mutated")
        copy.state = .complete
        
        #expect(original.body == AttributedString("original"))
        #expect(original.state == nil)
        #expect(copy.body == AttributedString("mutated"))
        #expect(copy.state == .complete)
    }
}
