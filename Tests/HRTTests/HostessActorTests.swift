//
//  HostessActorTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



// MARK: - Construction smoke tests

/// These check that each Hostess initializer returns without crashing
/// synchronously. They do not exercise the underlying Shelf — that happens
/// lazily on the first read/write through the actor.
@Suite("Hostess construction")
struct HostessConstructionTests {
    
    /// The default initializer should be callable. It constructs a generator
    /// closure but does not actually open a Shelf until the first method call.
    /// We never invoke a method here, so even though `Hostess()` would open the
    /// on-drive default store on first use, this test stays safely on the
    /// synchronous side of that boundary.
    @Test func defaultInitDoesNotCrash() {
        _ = Hostess()
    }
    
    
    /// Passing an explicit Shelf should be accepted; the actor takes ownership
    /// of that shelf for all subsequent reads and writes.
    @Test func explicitShelfInitDoesNotCrash() {
        _ = Hostess(.onlyInMemory())
    }
    
    
    /// Passing a generator closure should be accepted. The closure is not
    /// invoked at construction time — it runs when the first method needs a
    /// shelf.
    @Test func generatorInitDoesNotCrash() {
        _ = Hostess { Shelf.onlyInMemory() }
    }
    
    
    /// The generator-based initializer must not eagerly invoke the closure.
    /// If it did, a generator that records an Issue on entry would cause this
    /// test to fail.
    @Test func generatorIsLazy() {
        let neverCalled = Hostess { 
            Issue.record("Generator was invoked before any method call")
            return Shelf.onlyInMemory()
        }
        
        _ = neverCalled
    }
}



// MARK: - Save → fetch round trips

/// Integration-level tests that exercise the full path:
/// Hostess → SHELF → in-memory backing store → Hostess.
///
/// Each suite instance gets its own `Shelf.onlyInMemory()`, which the SHELF
/// docs guarantee is completely separate from any other shelf — so tests
/// neither share state nor touch the filesystem.
@Suite("Hostess persistence round trips")
struct HostessPersistenceTests {
    
    let hostess: Hostess
    
    
    init() {
        self.hostess = Hostess(.onlyInMemory())
    }
    
    
    
    // MARK: Tag (no references — the simplest case)
    
    /// Saving a tag and then asking for it by id should return an equivalent
    /// tag. Tags carry no references, so this isolates the actor's basic
    /// read/write plumbing from any reference-resolution concerns.
    @Test func tagRoundTrip() async throws {
        let tag = HostessTag(label: "groceries")
        
        try await hostess.save(tag)
        let fetched = try await hostess.tag(withId: tag.id)
        
        let unwrapped = try #require(fetched, "Tag should be retrievable by its id after save")
        #expect(unwrapped.id == tag.id)
        #expect(unwrapped.label == tag.label)
        #expect(unwrapped.kind == .tag)
    }
    
    
    /// Asking for a tag that was never saved should return nil — not throw,
    /// not crash, not return a placeholder.
    @Test func fetchingMissingTagReturnsNil() async throws {
        let fetched = try await hostess.tag(withId: ShelfId())
        
        #expect(fetched == nil)
    }
    
    
    /// A second save of the same tag (same id, mutated content) should
    /// overwrite the first. The id is the identity; the content is the value.
    @Test func tagSaveOverwrites() async throws {
        let id = ShelfId()
        let first = HostessTag(id: id, label: "draft")
        let second = HostessTag(id: id, label: "final")
        
        try await hostess.save(first)
        try await hostess.save(second)
        
        let fetched = try await hostess.tag(withId: id)
        let unwrapped = try #require(fetched)
        #expect(unwrapped.label == "final")
    }
    
    
    
    // MARK: Tasklist
    
    /// Saving a tasklist and fetching it back should preserve its name, state,
    /// and the ids of any subtask references it carries.
    @Test func tasklistRoundTrip() async throws {
        let subtaskId = ShelfId()
        let list = HostessTasklist(
            name: "weekly groceries",
            tasks: [HostessTasklist.Subtask(id: subtaskId)]
        )
        
        try await hostess.save(list)
        let fetched = try await hostess.tasklist(withId: list.id)
        
        let unwrapped = try #require(fetched, "Tasklist should be retrievable by its id after save")
        #expect(unwrapped.id == list.id)
        #expect(unwrapped.name == list.name)
        #expect(unwrapped.state == .open)
        #expect(unwrapped.kind == .tasklist)
        #expect(unwrapped.tasks == [HostessTasklist.Subtask(id: subtaskId)])
    }
    
    
    /// Asking for a tasklist that was never saved should return nil.
    @Test func fetchingMissingTasklistReturnsNil() async throws {
        let fetched = try await hostess.tasklist(withId: ShelfId())
        
        #expect(fetched == nil)
    }
    
    
    
    // MARK: Task
    
    /// Saving a task and fetching it back should preserve its body, parent
    /// reference, and state-related fields.
    @Test func taskRoundTrip() async throws {
        let parentId = ShelfId()
        let task = HostessTask(
            body: AttributedString("buy milk"),
            parent: HostessTask.Parent(id: parentId),
            state: .open,
            completionPercentage: 0.25
        )
        
        try await hostess.save(task)
        let fetched = try await hostess.task(withId: task.id)
        
        let unwrapped = try #require(fetched, "Task should be retrievable by its id after save")
        #expect(unwrapped.id == task.id)
        #expect(unwrapped.parent == HostessTask.Parent(id: parentId))
        #expect(unwrapped.state == .open)
        #expect(unwrapped.completionPercentage == 0.25)
        #expect(unwrapped.kind == .task)
    }
    
    
    /// Asking for a task that was never saved should return nil.
    @Test func fetchingMissingTaskReturnsNil() async throws {
        let fetched = try await hostess.task(withId: ShelfId())
        
        #expect(fetched == nil)
    }
    
    
    
    // MARK: Cross-type lookups
    
    /// Saving a tag and then asking `task(withId:)` for that same id should
    /// surface a parse error — because the persisted JSON carries a tag's
    /// fields (id, label) and the task decoder expects a task's fields
    /// (id, body, parent, …).
    ///
    /// `HostessStorageWrapper.init(from:)` decodes the payload BEFORE reading
    /// the type tag, so a wrong-typed fetch can't short-circuit; it has to
    /// fail at the inner payload decode and propagate as
    /// `Shelf.ReadError.couldNotParseObject` wrapped in `TaskFetchError.shelfError`.
    @Test func tagIdDoesNotResolveAsTask() async throws {
        let tag = HostessTag(label: "shared id test")
        try await hostess.save(tag)
        
        await #expect(throws: TaskFetchError.self) {
            _ = try await hostess.task(withId: tag.id)
        }
    }
    
    
    
    // MARK: Generic `any` fetch
    
    /// The generic `any(withId:)` should resolve to any saved object by id,
    /// returning the appropriate type when the caller asks for it.
    @Test func anyFetchResolvesTag() async throws {
        let tag = HostessTag(label: "anyfetch")
        try await hostess.save(tag)
        
        let fetched: HostessTag? = try await hostess.any(withId: tag.id)
        let unwrapped = try #require(fetched)
        #expect(unwrapped.id == tag.id)
        #expect(unwrapped.label == "anyfetch")
    }
}
