//
//  LiftError.swift
//  Lift
//
//  Created by Måns Bernhardt on 2017-04-03.
//  Copyright © 2017 iZettle. All rights reserved.
//

import Foundation

/// `LiftError` holds besides a description of the Error the `key` (or path) to where the error occured.
public struct LiftError: Error, CustomStringConvertible {
    /// The description of the error
    public let description: String
    
    /// The key (path) to where the error occured. Helpful for debugging.
    public let key: String
    
    /// The context jar. Helpful for debugging.
    public var context: String { return _context() }
    fileprivate let _context: () -> String
}


public extension LiftError {
    /// Creates an instance with a `description`.
    public init(_ description: String) {
        self.init(description, key: "", context: { "" })
    }
}

extension LiftError: CustomNSError {
    public static var errorDomain: String { return "com.izettle.lift" }
    public var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: "LiftError(description: \(description), key: \(key), context: \(context))"]
    }
}

public extension Jar {
    /// Will throw a `LiftError` using `self` to construct the error's key and context
    func assertionFailure(_ description: @autoclosure () -> String = "Assertion failure") -> LiftError {
        return LiftError(description(), context: self)
    }
    
    /// Will throw a `LiftError` if `condition` is false using `self` to construct the error's key and context
    func assert(_ condition: @autoclosure () throws -> Bool, _ description: @autoclosure () -> String = "Assertion failure") throws {
        if try !condition() {
            throw LiftError(description(), context: self)
        }
    }
    
    /// Will throw a `LiftError` if `val` is nil using `self` to construct the error's key and context
    func assertNotNil<T>(_ val: T?, _ description: @autoclosure () -> String = "Expected value missing") throws -> T {
        switch val {
        case let val?:
            return val
        case nil:
            throw assertionFailure(description)
        }
    }
}

extension Optional {
    /// Will try to unwrap the `self` and throw a `LiftError` using `description` if unsuccessful
    func assertNotNil(_ description: @autoclosure () -> String = "Expected value missing") throws -> Wrapped {
        switch self {
        case nil:
            throw LiftError(description())
        case let val?:
            return val
        }
    }
}

extension LiftError {
    init(error: LiftError, key: String, context jar: Jar) {
        self.key = key.isEmpty ? error.key : key + ((error.key.isEmpty || error.key.hasPrefix("[")) ? error.key : ( "." + error.key))
        description = error.description
        _context = { error.context.isEmpty ? jar.contextDescription : error.context }
    }
    
    init(_ description: String, key: String, context: @escaping () -> String) {
        self.key = key
        self.description = description
        _context = context
    }
    
    init(_ description: String, key: String? = nil, context jar: Jar) {
        self.init(description, key: key ?? jar.key(), context: { jar.contextDescription })
    }
}


