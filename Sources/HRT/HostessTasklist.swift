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
    
    /// Universally identifies this tasklist
    public var id: ShelfId = .init()
    
    
    
    /// This array lists the IDs of all of this tasklist's subtasks.
    public var tasks: [ShelfId]
    
    /// A list of IDs of tags which apply to this tasklist
    public var tags: [ShelfId]? = nil
    
    
    public init(id: ShelfId = .init(), tasks: [ShelfId], tags: [ShelfId]? = nil) {
        self.id = id
        self.tasks = tasks
        self.tags = tags
    }
}



// MARK: - Conformances

extension HostessTasklist: Codable {}
extension HostessTasklist: Sendable {}
extension HostessTasklist: ShelfData {}
extension HostessTasklist: Identifiable {}
