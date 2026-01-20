//
//  HostessObject + IdealPayload.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import SHELF



public extension HostessObject {
    typealias IdealPayload = HostessObjectIdealPayload
}



public typealias HostessObjectIdealPayload = Codable & Sendable & ShelfData & Identifiable
