//
//  EitherSHELFTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("Either + SHELF retroactive conformances")
struct EitherSHELFTests {
    
    // MARK: Helpers
    
    /// Build a task with a known id and a dummy parent reference so we can
    /// observe id propagation through the Either wrapper.
    private func makeTask(id: ShelfId = .init()) -> HostessTask {
        HostessTask(
            id: id,
            body: AttributedString("test task"),
            parent: HostessTask.Parent(id: ShelfId())
        )
    }
    
    
    private func makeTasklist(id: ShelfId = .init()) -> HostessTasklist {
        HostessTasklist(
            id: id,
            name: "test list",
            tasks: []
        )
    }
    
    
    
    // MARK: - Identifiable / ShelfIdentifiable conformance
    
    /// When a task is wrapped on the `.left` side, the Either should expose the
    /// task's id verbatim — no wrapping, no transformation.
    @Test func leftSidePropagatesTaskId() {
        let task = makeTask()
        let parent: HostessTaskParent = .left(task)
        
        #expect(parent.id == task.id)
    }
    
    
    /// And the `.right` side should likewise expose the tasklist's id.
    @Test func rightSidePropagatesTasklistId() {
        let list = makeTasklist()
        let parent: HostessTaskParent = .right(list)
        
        #expect(parent.id == list.id)
    }
    
    
    /// Different inner payloads on the same side should produce different ids —
    /// confirming that the Either really reads from the inner value rather than
    /// caching or substituting.
    @Test func differentTasksGiveDifferentIds() {
        let taskA = makeTask()
        let taskB = makeTask()
        let parentA: HostessTaskParent = .left(taskA)
        let parentB: HostessTaskParent = .left(taskB)
        
        #expect(parentA.id != parentB.id)
        #expect(parentA.id == taskA.id)
        #expect(parentB.id == taskB.id)
    }
    
    
    /// Two Eithers carrying the same id-bearing payload on opposite sides should
    /// report equal ids — the side of the Either doesn't change identity.
    @Test func sameIdOnDifferentSidesYieldsEqualIds() {
        let sharedId = ShelfId()
        let task = makeTask(id: sharedId)
        let list = makeTasklist(id: sharedId)
        
        let parentL: HostessTaskParent = .left(task)
        let parentR: HostessTaskParent = .right(list)
        
        #expect(parentL.id == parentR.id)
        #expect(parentL.id == sharedId)
    }
    
    
    /// The id surfaced by the Either must be typed as ShelfId — proving the
    /// ShelfIdentifiable conformance is the one in effect, not just the generic
    /// Identifiable conformance.
    @Test func idTypeIsShelfId() {
        let task = makeTask()
        let parent: HostessTaskParent = .left(task)
        
        // If the ShelfIdentifiable conformance is wired correctly, this
        // assignment compiles without an `as` cast.
        let id: ShelfId = parent.id
        
        #expect(id == task.id)
    }
}
