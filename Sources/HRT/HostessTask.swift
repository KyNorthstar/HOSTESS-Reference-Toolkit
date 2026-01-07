//
//  HostessTask.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

import SHELF



/// A task in HOSTESS
public struct HostessTask {
    
    /// Universally identifies this task 
    public var id: ShelfId
    
    
    /// The body text of the task
    public var body: AttributedString
    
    /// Any ancillary notes attached to the task
    public var notes: AttributedString? = nil
    
    /// If this task is a child of another task, this is that other task's ID.
    /// This is `nil` when this task is a top-level task
    ///
    /// - Note: It's possible for semi-orphaned tasks to exist, which have this task's ID in its subtasks array, but this field is `nil` or some other ID. In that case, the graph is in an invalid state in need of repair. It's still worth attempting to show such tasks to the user in a way they might expect.
    public var parent: ShelfId? = nil
    
    /// If this task contains child tasks, this array lists the IDs of all of those.
    /// This is `nil` or empty when this task has no child tasks.
    ///
    /// - Note: It's possible for semi-orphaned tasks to exist, which have this task's ID as a parent ID, but which don't appear in this array. In that case, the graph is in an invalid state in need of repair. It's still worth attempting to show such tasks to the user in a way they might expect.
    public var subtasks: [ShelfId]? = nil
    
    /// A list of IDs of tags which apply to this task
    public var tags: [ShelfId]? = nil
    public var state: State? = nil
    public var completionPercentage: CGFloat? = nil
}



extension HostessTask {
    public enum State: String {
        case open
        case complete
        case dropped
    }
}



// MARK: - Conformances

extension HostessTask: Codable {}
extension HostessTask: Sendable {}
extension HostessTask: ShelfData {}

extension HostessTask.State: Codable {}
extension HostessTask.State: Sendable {}
