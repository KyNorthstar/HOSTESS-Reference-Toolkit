//
//  type restrictions.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-20.
//

import Foundation



/// Any & all HOSTESS types conform to this
public typealias AnyHostessType = Sendable

///// Any HOSTESS object which can be persisted to the store
//public typealias HostessDirectShelfObject = AnyHostessType & ShelfData



/// The payload of every HOSTESS object should conform to this
public protocol HostessPayload: AnyHostessType & Codable {
    
    /// Which kind of HOSTESS object is this?
    var kind: HostessObjectKind { get }
}
