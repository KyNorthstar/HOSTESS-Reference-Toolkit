//
//  HostessObjectState.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-02-16.
//

import Foundation


/// The current broad state of a HOSTESS object
public enum HostessObjectState: String {
    
    /// The task has been created and can currently be worked on
    case open
    
    /// The task has been completed, successfully or not
    case complete
    
    /// The task was not completed and is no longer going to be worked on
    case dropped
}



// MARK: - Conformance

extension HostessObjectState: AnyHostessType {}
extension HostessObjectState: Codable {}
