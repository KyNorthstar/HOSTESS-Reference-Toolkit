//
//  HostessTask.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-04.
//

import Foundation



/// A task in HOSTESS
public struct HostessTask: Codable {
    public var body: AttributedString
    public var parent: UUID
    public var tags: [UUID]
    public var state: State
    public var completionPercentage: CGFloat? = nil
}



extension HostessTask {
    public enum State: String, Codable {
        case open
        case complete
        case dropped
    }
}
