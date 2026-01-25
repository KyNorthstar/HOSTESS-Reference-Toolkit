//
//  HostessTask + Completion.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-20.
//

import Foundation



public extension HostessTask {
    
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
            case .notStarted:                   .complete
          //case .inProgress(percentage: ...0): .complete
            case .inProgress(percentage: _):    .complete
            case .inProgress(percentage: 1...): .notStarted
            case .complete:                     .notStarted
            case .dropped:                      .notStarted
            }
            
        case .toggleDroppedAndNotStarted:
            switch self {
            case .notStarted:                .dropped
            case .inProgress(percentage: _): .dropped
            case .complete:                  .dropped
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
        
        /// Toggling selects either `.dropped` or `.notStarted`.
        ///
        /// Here's how the state changes when you toggle the completion:
        /// - `.notStarted` becomes `.dropped`
        /// - `.inProgress` becomes `.dropped`
        /// - `.complete` becomes `.dropped`
        /// - `.dropped` becomes `.notStarted`
        case toggleDroppedAndNotStarted
        
        
        
        /// A reasonable default toggle behavior.
        ///
        /// This might change between releases, but will always be a reasonable default toggle behavior that a user might expect
        public static var `default`: Self { .toggleCompleteAndNotStarted }
    }
}



// MARK: - conformance

extension HostessTask.Completion: AnyHostessType {}
extension HostessTask.Completion: Equatable {}

extension HostessTask.Completion.ToggleBehavior: AnyHostessType {}



// MARK: - HostessTask integration

public extension HostessTask.Completion {
    /// Uses the two given signals to build a more-useful single "completion" value
    ///
    /// - Parameters:
    ///   - state:                The general state of a task. `nil` indicates unknown or unimportant
    ///   - completionPercentage: how complete a task is. `nil` indicates that unknown or not applicable
    init(taskState state: HostessTask.State?, completionPercentage: CGFloat?) {
        guard let state else {
            if let completionPercentage {
                self = .inProgress(percentage: completionPercentage)
            }
            else {
                self = .notStarted
            }
            return
        }
        
        switch state {
        case .open:
            if let completionPercentage,
               completionPercentage > 0
            {
                if completionPercentage > 1 {
                    self = .complete
                }
                else {
                    self = .inProgress(percentage: completionPercentage)
                }
            }
            else {
                self = .notStarted
            }
            
        case .complete: self = .complete
        case .dropped: self = .dropped
        }
    }
}



public extension HostessTask {
    
    /// How complete this task is.
    ///
    /// The return value is calculated based on the fields of this task.
    /// When you set this, the fields of this task are automatically changed to reflect your new value.
    var completion: Completion {
        get {
            .init(taskState: state, completionPercentage: completionPercentage)
        }
        
        set {
            self.state = newValue.taskState
            self.completionPercentage = newValue.completionPercentage
        }
    }
}



// MARK: - Return to primitives

public extension HostessTask.State {
    /// Creates a task state analogous to the given task completion 
    init(_ completion: HostessTask.Completion) {
        self = switch completion {
        case .notStarted:                .open
        case .inProgress(percentage: _): .open
        case .complete:                  .complete
        case .dropped:                   .dropped
        }
    }
}

public extension HostessTask.Completion {
    /// Converts this completion into a task's state vlaue
    var taskState: HostessTask.State {
        .init(self)
    }
    
    
    /// Extracts only the percentage view of completion, for use in places (like ``HostessTask``) where the percentage completion is separate from the task state
    var completionPercentage: CGFloat? {
        switch self {
        case .notStarted:
            nil
        case .inProgress(let percentage):
            percentage
        case .complete:
            1
        case .dropped:
            nil
        }
    }
}
