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
    
    /// The current broad state of this task
    public var state: State? = nil
    
    /// How complete is the current task? `0.0`~`1.0`
    public var completionPercentage: CGFloat? = nil
    
    
    public init(id: ShelfId, body: AttributedString, notes: AttributedString? = nil, parent: ShelfId? = nil, subtasks: [ShelfId]? = nil, tags: [ShelfId]? = nil, state: State? = nil, completionPercentage: CGFloat? = nil) {
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



// MARK: - Completion

public extension HostessTask {
    
    /// How complete this task is.
    ///
    /// The return value is calculated based on the fields of this task.
    /// When you set this, the fields of this task are automatically changed to reflect your new value.
    var completion: Completion {
        get {
            guard let state else {
                if let completionPercentage {
                    return .inProgress(percentage: completionPercentage)
                }
                else {
                    return .notStarted
                }
            }
            
            switch state {
            case .open:
                if let completionPercentage,
                   completionPercentage > 0
                {
                    if completionPercentage > 1 {
                        return .complete
                    }
                    else {
                        return .inProgress(percentage: completionPercentage)
                    }
                }
                else {
                    return .notStarted
                }
                
            case .complete: return .complete
            case .dropped: return .dropped
            }
        }
        
        set {
            switch newValue {
            case .notStarted:
                self.state = .open
                self.completionPercentage = nil
                
            case .inProgress(percentage: let percentage):
                self.state = .open
                self.completionPercentage = percentage
                
            case .complete:
                self.state = .complete
                self.completionPercentage = 1
                
            case .dropped:
                self.state = .dropped
                self.completionPercentage = nil
            }
        }
    }
    
    
    
    /// How complete a task is
    enum Completion {
        
        /// The task hasn't yet been started
        case notStarted
        
        /// The task is currently being worked on
        /// - Parameter percentage: How far along is the progress? `0.0`~`1.0`
        case inProgress(percentage: CGFloat)
        
        /// The task is fully complete (or at least complete enough to be marked as complete)
        case complete
        
        /// The task is incomplete but will not be worked on
        case dropped
    }
}



public extension HostessTask.Completion {
    
    /// Change this completion value to its inverse.
    ///
    /// - Parameter behavior: _optional_ - The exact behavior of toggling this completion. Default to `.default`.
    mutating func toggle(withBehavior behavior: ToggleBehavior = .default) {
        self = inverse(withBehavior: behavior)
    }
    
    
    
    /// Returns the inverse of this completion
    ///
    /// - Parameter behavior: The exact behavior of inverting this completion
    private func inverse(withBehavior behavior: ToggleBehavior) -> Self {
        switch behavior {
        case .toggleCompleteAndNotStarted:
            switch self {
            case .notStarted:                .complete
            case .inProgress(percentage: _): .complete
            case .complete:                  .notStarted
            case .dropped:                   .notStarted
            }
        }
    }
    
    
    
    /// How ``toggle()`` behaves
    enum ToggleBehavior {
        
        /// Toggling selects either `.complete` or `.notStarted`.
        ///
        /// Here's how the state changes when you toggle the completion:
        /// - `.notStarted` becomes `.complete`
        /// - `.inProgress` becomes `.complete`
        /// - `.complete` becomes `.notStarted`
        /// - `.dropped` becomes `.notStarted`
        case toggleCompleteAndNotStarted
        
        
        /// A reasonable default toggle behavior.
        ///
        /// This might change between releases, but will always be a reasonable default toggle behavior that a user might expect
        public static var `default`: Self { .toggleCompleteAndNotStarted }
    }
}



// MARK: - Conformances

extension HostessTask: Codable {}
extension HostessTask: Sendable {}
extension HostessTask: ShelfData {}

extension HostessTask.State: Codable {}
extension HostessTask.State: Sendable {}
