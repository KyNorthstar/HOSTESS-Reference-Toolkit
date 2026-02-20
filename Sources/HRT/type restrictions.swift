//
//  type restrictions.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-20.
//

import Foundation



/// Any & all HOSTESS types conform to this
public typealias AnyHostessType = Sendable

/// Any HOSTESS object which can be persisted to the store
public typealias AnyPersistedHostessObject = AnyHostessType & ShelfData
