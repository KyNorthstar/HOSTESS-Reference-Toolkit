//
//  HostessTasklistTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessTasklist")
struct HostessTasklistTests {
    
    @Test("Initializer populates the supplied fields and uses sensible defaults")
    func initializerPopulatesFields() {
        let id = ShelfId()
        let list = HostessTasklist(
            id: id,
            name: "Groceries",
            tasks: []
        )
        
        #expect(list.id == id)
        #expect(list.name == "Groceries")
        #expect(list.tasks.isEmpty)
        #expect(list.notes == nil, "notes should default to nil when omitted")
        #expect(list.tags == nil, "tags should default to nil when omitted")
    }
    
    
    /// A new tasklist defaults to `.open` because a list that's already
    /// `.complete` or `.dropped` at creation time would be a strange
    /// thing to construct directly.
    @Test("Default state is .open")
    func defaultStateIsOpen() {
        let list = HostessTasklist(name: "fresh list", tasks: [])
        #expect(list.state == .open)
    }
    
    
    @Test("Explicit state is honored")
    func explicitStateIsHonored() {
        let list = HostessTasklist(name: "done list", tasks: [], state: .complete)
        #expect(list.state == .complete)
    }
    
    
    @Test("Omitting the id auto-generates a fresh, unique one")
    func defaultIdIsUnique() {
        let a = HostessTasklist(name: "x", tasks: [])
        let b = HostessTasklist(name: "x", tasks: [])
        
        #expect(a.id != b.id, "Two tasklists with the same name should still have distinct ids")
    }
    
    
    @Test("kind is always .tasklist")
    func kindIsAlwaysTasklist() {
        let list = HostessTasklist(name: "x", tasks: [])
        #expect(list.kind.rawValue == HostessObjectKind.tasklist.rawValue)
    }
    
    
    @Test("name and state are mutable")
    func fieldsAreMutable() {
        var list = HostessTasklist(name: "before", tasks: [])
        list.name = "after"
        list.state = .dropped
        
        #expect(list.name == "after")
        #expect(list.state == .dropped)
    }
    
    
    /// Subtask references are carried as opaque references — the tasklist
    /// shouldn't need to resolve them just to be initialized or copied.
    @Test("A tasklist can carry subtask references without resolving them")
    func canCarryReferencesWithoutResolving() {
        let subtaskIds = [ShelfId(), ShelfId(), ShelfId()]
        let references: [HostessTasklist.Subtask] = subtaskIds.map { .init(id: $0) }
        
        let list = HostessTasklist(name: "with subtasks", tasks: references)
        
        #expect(list.tasks.count == 3)
    }
}
