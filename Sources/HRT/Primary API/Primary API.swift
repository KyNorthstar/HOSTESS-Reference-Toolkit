//
//  Primary API.swift
//  HOSTESS Reference Toolkit
//
//  Created by Ky on 2026-02-16.
//

import Foundation

import ConcurrencyTools
import FunctionTools
import SHELF



/// Use this actor to interface with HOSTESS in a nice clean way
public actor Hostess {
    private var currentShelf: ThrowingAsyncBinding<Shelf, Shelf.InitError>
    
    
    public init(_ shelfGenerator: @escaping ThrowingAsyncBinding<Shelf, Shelf.InitError>.Get) {
        currentShelf = ThrowingAsyncBinding(shelfGenerator)
    }
    
    
    public init(_ shelf: Shelf) {
        currentShelf = ThrowingAsyncBinding(shelf)
    }
    
    
    public init() {
        currentShelf = ThrowingAsyncBinding { try! await Shelf() }
    }
}



// MARK: - SHELF integration

//@globalActor
//public final actor ShelfMutex: GlobalActor {
//    public static let shared = ShelfMutex()
//}
//
//
//
//public extension ShelfMutex {
//    @ShelfMutex
//    static func run<Value>(_ action: @ShelfMutex () -> Value) -> Value {
//        action()
//    }
//    
//    
//    @ShelfMutex
//    static func run<Value, Failure>(_ action: @ShelfMutex () throws(Failure) -> Value) throws(Failure) -> Value {
//        try action()
//    }
//    
//    
//    @ShelfMutex
//    static func run<Value>(_ action: @ShelfMutex () async -> Value) async -> Value {
//        await action()
//    }
//    
//    
//    @ShelfMutex
//    static func run<Value, Failure>(_ action: @ShelfMutex () async throws(Failure) -> Value) async throws(Failure) -> Value {
//        try await action()
//    }
//}



private extension Hostess {
    func object<Object, Failure>(
        withId id: HostessId,
        onError: (Shelf.ReadError) -> Failure)
    async throws(Failure) -> Object?
    where Object: HostessPayload,
          Failure: Error
    {
        let shelf = try! await currentShelf.wrappedValue
        do {
            let wrapped: HostessStorageWrapper<Object>? = try await shelf.object(withId: id)
            return wrapped?.payload
        }
        catch {
            throw onError(error)
        }
    }
    
    
    func save<Object, Failure>(
        _ object: Object,
        onError: (Shelf.WriteError) -> Failure)
    async throws(Failure)
    where Object: HostessIdealStoragePayload,
          Failure: Error
    {
        var shelf = try! await currentShelf.wrappedValue
        do {
            try await shelf.save(HostessStorageWrapper(wrapping: object))
            await currentShelf.setWrappedValue(shelf)
        }
        catch {
            throw onError(error)
        }
    }
}



// MARK: - Tasks

// MARK: Fetching

public extension Hostess {
    func task(withId id: HostessId) async throws(TaskFetchError) -> HostessTask? {
        try await object(withId: id, onError: { TaskFetchError.shelfError($0) })
    }
}



public enum TaskFetchError: Error {
    case shelfError(Shelf.ReadError)
}



// MARK: Saving

public extension Hostess {
    func save(_ task: HostessTask) async throws(TaskSaveError) {
        try await save(task, onError: { TaskSaveError.shelfError($0) })
    }
}



public enum TaskSaveError: Error {
    case shelfError(Shelf.WriteError)
}



// MARK: - Tasklists

// MARK: Fetching

public extension Hostess {
    func tasklist(withId id: HostessId) async throws(TasklistFetchError) -> HostessTasklist? {
        try await object(withId: id, onError: { TasklistFetchError.shelfError($0) })
    }
}



public enum TasklistFetchError: Error {
    case shelfError(Shelf.ReadError)
}



// MARK: Saving

public extension Hostess {
    func save(_ tasklist: HostessTasklist) async throws(TasklistSaveError) {
        try await save(tasklist, onError: { TasklistSaveError.shelfError($0) })
    }
}



public enum TasklistSaveError: Error {
    case shelfError(Shelf.WriteError)
}



// MARK: - Tags

// MARK: Fetching

public extension Hostess {
    func tag(withId id: HostessId) async throws(TagFetchError) -> HostessTag? {
        try await object(withId: id, onError: { TagFetchError.shelfError($0) })
    }
}



public enum TagFetchError: Error {
    case shelfError(Shelf.ReadError)
}



// MARK: Saving

public extension Hostess {
    func save(_ tag: HostessTag) async throws(TagSaveError) {
        try await save(tag, onError: { TagSaveError.shelfError($0) })
    }
}



public enum TagSaveError: Error {
    case shelfError(Shelf.WriteError)
}



// MARK: - Custom objects

// MARK: Fetching

public extension Hostess {
    func any<Payload: HostessIdealStoragePayload>(withId id: HostessId) async throws(AnyFetchError) -> Payload? {
        try await object(withId: id, onError: { AnyFetchError.shelfError($0) })
    }
}



public enum AnyFetchError: Error {
    case shelfError(Shelf.ReadError)
}



// MARK: Saving

public extension Hostess {
    func save<Payload: HostessIdealStoragePayload>(any payload: Payload) async throws(AnySaveError) {
        try await save(payload, onError: { AnySaveError.shelfError($0) })
    }
}



public enum AnySaveError: Error {
    case shelfError(Shelf.WriteError)
}
