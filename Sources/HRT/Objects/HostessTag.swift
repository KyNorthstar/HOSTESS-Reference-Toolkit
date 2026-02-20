//
//  HostessTag.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation

import SHELF



/// A tag in HOSTESS
public struct HostessTag {
    
    /// Universally identifies this task 
    public var id: ShelfId = .init()
    
    
    /// The label text of the tag
    public var label: String
    
    
    public init(id: ShelfId = .init(), label: String) {
        self.id = id
        self.label = label
    }
}



// MARK: - Conformances

extension HostessTag: HostessStorageWrapper.IdealPayload {
    public var kind: HostessObjectKind { .tag }
}
