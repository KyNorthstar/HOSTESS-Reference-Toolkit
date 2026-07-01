//
//  HostessObject + IdealPayload.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import SHELF



public typealias HostessId = ShelfId



public extension HostessStorageWrapper {
    typealias IdealPayload = HostessIdealStoragePayload
}



public typealias HostessIdealStoragePayload = HostessPayload & ShelfData
