//
//  Either + SHELF.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-29.
//

import Foundation

import Either



extension Either: @retroactive Identifiable where Left: Identifiable, Right: Identifiable, Left.ID == Right.ID {
    
    public typealias ID = Left.ID
    
    
    
    public var id: ID {
        switch self {
        case .left(let value):
            return value.id
            
        case .right(let value):
            return value.id
        }
    }
}



extension Either: @retroactive ShelfIdentifiable where Self: Identifiable, Left: ShelfIdentifiable, Right: ShelfIdentifiable, Left.ID == Right.ID {
    public var id: ShelfId {
        switch self {
        case .left(let value):
            return value.id
            
        case .right(let value):
            return value.id
        }
    }
}



extension Either: @retroactive ShelfData where Self: ShelfIdentifiable, Left: ShelfData, Right: ShelfData {
    
}
