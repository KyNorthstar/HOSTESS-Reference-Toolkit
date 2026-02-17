//
//  HostessTask.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

import SHELF



/// A tasklist in HOSTESS
public struct HostessTasklist {
    
    public typealias Subtask = ShelfObjectReference<HostessTask>
    public typealias Tag = ShelfObjectReference<HostessTag>
    
    
    
    /// Universally identifies this tasklist
    public var id: ShelfId = .init()
    
    
    /// The user-facing name of this tasklist
    public var name: String
    
    /// The user-facing name of this tasklist
    public var notes: AttributedString? = nil
    
    /// This array lists the IDs of all of this tasklist's subtasks.
    public var tasks: [Subtask]
    
//    /// This array lists the IDs of all of the groups which are known to contain this tasklist.
//    public var parentGroups: [ParentGroup]
    
    /// A list of IDs of tags which apply to this tasklist
    public var tags: [Tag]? = nil
    
    /// The current broad state of this tasklist
    public var state: State = .open
    
    /// How complete is the current tasklist? `0.0`~`1.0`
    public var completionPercentage: CGFloat? = nil
    
    
    public init(id: ShelfId = .init(), name: String, notes: AttributedString? = nil, tasks: [Subtask], tags: [Tag]? = nil, state: State = .open) {
        self.id = id
        self.name = name
        self.notes = notes
        self.tasks = tasks
        self.tags = tags
        self.state = state
    }
}



public extension HostessTasklist {
    
    /// The current broad state of a tasklist
    typealias State  = HostessObjectState
}



// MARK: - Conformances

extension HostessTasklist: HostessObject.IdealPayload {}
