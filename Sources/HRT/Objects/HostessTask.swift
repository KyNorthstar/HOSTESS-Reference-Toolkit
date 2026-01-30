//
//  HostessTask.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

import Either
import SHELF



/// A task in HOSTESS
public struct HostessTask {
    
    public typealias Parent = ShelfObjectReference<HostessTaskParent>
    
    
    
    /// Universally identifies this task 
    public var id: ShelfId = .init()
    
    
    /// The body text of the task
    public var body: AttributedString
    
    /// Any ancillary notes attached to the task
    public var notes: AttributedString? = nil
    
    /// Each task must be a child of something (usually a tasklist or another task). This is the ID of that.
    ///
    /// - Note: It's possible for semi-orphaned tasks to exist, which have this task's ID in its subtasks array, but this field is some other ID. In that case, the graph is in an invalid state in need of repair. It's still worth attempting to show such tasks to the user in a way they might expect.
    public var parent: Parent
    
    /// If this task contains child tasks, this array lists the IDs of all of those.
    /// This is `nil` or empty when this task has no child tasks.
    ///
    /// - Note: It's possible for semi-orphaned tasks to exist, which have this task's ID as a parent ID, but which don't appear in this array. In that case, the graph is in an invalid state in need of repair. It's still worth attempting to show such tasks to the user in a way they might expect.
    public var subtasks: [ShelfId]? = nil
    
    /// A list of IDs of tags which apply to this task
    public var tags: [ShelfId]? = nil
    
    /// The current broad state of this task
    public var state: State? = nil
    
    /// How complete is the current task? `0.0`~`1.0`
    public var completionPercentage: CGFloat? = nil
    
    
    public init(id: ShelfId = .init(), body: AttributedString, notes: AttributedString? = nil, parent: Parent, subtasks: [ShelfId]? = nil, tags: [ShelfId]? = nil, state: State? = nil, completionPercentage: CGFloat? = nil) {
        self.id = id
        self.body = body
        self.notes = notes
        self.parent = parent
        self.subtasks = subtasks
        self.tags = tags
        self.state = state
        self.completionPercentage = completionPercentage
    }
}



public extension HostessTask {
    
    /// The current broad state of a task
    enum State: String {
        
        /// The task has been created and can currently be worked on
        case open
        
        /// The task has been completed, successfully or not
        case complete
        
        /// The task was not completed and is no longer going to be worked on
        case dropped
    }
}



// MARK: - Ancillary types

/// Any type which can be the parent of a task
public typealias HostessTaskParent = Either<HostessTask, HostessTasklist>



// MARK: - Conformances

extension HostessTask: HostessObject.IdealPayload {}

extension HostessTask.State: AnyHostessType {}
extension HostessTask.State: Codable {}
