//
//  Jar+Context.swift
//  Lift
//
//  Created by Måns Bernhardt on 2017-04-03.
//  Copyright © 2017 iZettle. All rights reserved.
//

import Foundation

/// Conforming types can be added to a Jar.Context to pass additional data not provided in the Jar value itself.
public protocol JarContextValue {
    var context: Jar.Context { get }
}

public extension Jar {
    /// Context is a type that a `Jar` can carry around holding context information needed that is not provided by the JSON itself.
    /// It can also be used to customize the behaviour of encoding and decoding of a type. E.g. `Date`'s conformance to JarElement will use the DateFormatter if any in provided context to encode and decodes dates.
    struct Context {
        fileprivate var vals = [String: Any]()

        init(key: String, value: Any) {
            vals = [ key: value ]
        }

        init(value: Any) {
            self.init(key: String(reflecting: type(of: value)), value: value)
        }

        public init(_ vals: [JarContextValue?] = []) {
            for val in vals.compactMap({ $0 }) {
                self.vals[String(reflecting: type(of: val))] = val
            }
        }

        public init(_ vals: JarContextValue?...) {
            self.init(vals)
        }
    }

    /// Creates a union between `self` context and `val`, where `val` context values will be replacing the same context value's in `self`'s context if they already exists
    func union(context val: JarContextValue?) -> Jar {
        var jar = self
        jar.context.formUnion(val)
        return jar
    }
}

public extension Jar.Context {
    /// Mutating version of `union`
    public mutating func formUnion(_ context: JarContextValue?) {
        for (key, val) in context?.context.vals ?? [:] {
            self.vals[key] = val
        }
    }

    /// Creates a union between `self` and `val`, where `val`'s context values will be replacing the same context value's in `self` if they already exists
    public func union(_ val: JarContextValue?) -> Jar.Context {
        var context = self
        context.formUnion(val)
        return context
    }

    /// Get a value of a certain type out of the context or throw if it does not exists
    public func get<T: JarContextValue>(_ type: T.Type = T.self) throws -> T {
        return try (vals[String(reflecting: type)] as? T).assertNotNil("The Jar context does not contain any value of type: \(type)")
    }

    /// Get a value of a certain type out of the context or return nil if it does not exists
    public func get<T: JarContextValue>(_ type: T?.Type = T?.self) -> T? {
        return vals[String(reflecting: T.self)].map { $0 as! T }
    }
}

extension Jar.Context: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JarContextValue?...) {
        self.init(elements)
    }
}

public extension JarContextValue {
    var context: Jar.Context { return Jar.Context(self) }
}

extension Jar.Context: JarContextValue {
    public var context: Jar.Context { return self }
}
