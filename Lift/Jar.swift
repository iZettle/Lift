//
//  Liftable.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// `Jar` is used to access heterogenous objects such as JSON, plists and user defaults in a type safe manner.
///
/// To lift values out of a `Jar` the 'lift' operator ^ is used, for example:
///
///     let jar = Jar(unchecked: any)
///     let int: Int = try json["val"]^
///
/// For a value to be liftable it must conform to `Liftable` or `JarConvertible`
public struct Jar {
    internal var object: Object
    internal var key: () -> String = { "" } // Capturing of the current key used for lazy evalution (to avoid a peformance hit for happy cases)
    public var context: Context = []
}

public extension Jar {
    /// Creates an empty instance not containing any value.
    init() {
        object = .none(context: { "" })
    }
 
    /// Creates an instance wrapping a primitive `value` conforming to `JarRepresentable`
    init(_ value: JarRepresentable) {
        object = .primitive({ try value.asJar(using: $0).asAny() })
    }
    
    /// Creates an instance wrapping a dictionary with values conforming to `JarRepresentable`
    init<S: CustomStringConvertible, T: JarRepresentable>(_ dictionary: [S: T]) {
        object = .dictionary([{ context in
            var result = [String: Any]()
            for (key, val) in dictionary {
                result[key.description] = try val.asJar(using: context).object.optionallyUnwrap(context)
            }
            return result
        }])
    }
    
    /// Creates an instance wrapping a dictionary with values conforming to `JarRepresentable`
    init<S: CustomStringConvertible>(_ dictionary: [S: JarRepresentable]) {
        object = .dictionary([{ context in
            var result = [String: Any]()
            for (key, val) in dictionary {
                result[key.description] = try val.asJar(using: context).object.optionallyUnwrap(context)
            }
            return result
        }])
    }
    
    /// Creates an instance wrapping an array with values conforming to `JarRepresentable`
    init<S: Sequence>(_ elements: S) where S.Iterator.Element: JarRepresentable {
        object = .array([ (nil, { context in
            try elements.map { $0.asJar(using: context) }.flatMap {
                return try $0.object.optionallyUnwrap($0.context).flatMap { $0 }
            }
        })])
    }

    /// Creates an instance wrapping an optional value conforming to `JarRepresentable`
    init(_ value: Optional<JarRepresentable>) {
        switch value {
        case let val?:
            self.init(val)
        case nil:
            self.init()
        }
    }
    
    /// Creates a `Jar` from an unknown `Any` value that might come from deserializing JSON etc.
    /// All leaf nodes that are `JarRepresentable` will be dropped down to `Any`
    /// - Throws: Unless `value` conform to `JarRepresentable`, or if the `value` is an array with elements conforming to `JarRepresentable`, or if `value` is a dictionary with `String` keys and values conforming to `JarRepresentable`
    init(checked value: Any?, context: Context = []) throws {
        self.object = try Object(value.map { try convert($0, context: context) })
    }

    /// Creates a `Jar` from an unknown `Any` value that might come from deserializing JSON etc.
    /// The content of `value` is not checked if it is `JarRepresentable` until first access.
    /// This is typically more efficient, espcially when you know your sources.
    /// - Postcondition: all leaf nodes are primitive values and not custom type so no need to dropping is required.
    init(unchecked value: Any?) {
        self.object = Object(value)
    }

    /// Creates a `Jar` that will throw `error` when it's value is lifted.
    init(error: Error) {
        self.object = .error(error)
    }
}

public extension Jar {
    /// Return the `Any` representation of the `Jar`'s wrapped value.
    /// - Throws: If the Jar is empty or contains an error.
    func asAny() throws -> Any {
        do {
            return try object.unwrap(context)
        } catch let error as LiftError {
            throw LiftError(error: error, key: self.key(), context: self)
        }
    }
}

/// Null type for explicit marking of nulls in jar's
public typealias Null = NSNull

/// null value for explicit marking of nulls in jar's
public let null = Null()

public extension Jar {
    /// Lifts a value of type `T` and applies `transform` to it
    func map<T: Liftable, O>(_ transform: (T) throws -> O) throws -> O where T.To == T {
        let value: T = try self^
        do {
            return try transform(value)
        } catch let error as LiftError {
            throw LiftError(error: error, key: self.key(), context: self)
        }
    }
    
    /// Lifts a value of type `T` if not nil and applies `transform` to it
    func map<T: Liftable, O>(_ transform: (T) throws -> O) throws -> O? where T.To == T {
        return try map { try $0.map(transform) }
    }
}


postfix operator ^

/// Lift a value out of a Jar
public postfix func ^<T: Liftable>(jar: Jar) throws -> T where T.To == T {
    return try T.lift(from: jar)
}

/// Lift an optional value out of a Jar
public postfix func ^<T: Liftable>(jar: Jar) throws -> T? where T.To == T {
    return try jar.map { try $0^ }
}

extension Jar: JarConvertible, JarRepresentable  {
    public init(jar: Jar) throws {
        object = jar.object
        context = jar.context
        key = jar.key
    }
    
    public var jar: Jar {
        return self
    }
}

extension Jar {
    func map<U>(_ f: (Jar) throws -> U) throws -> U? {
        switch self.object {
        case .none: return nil
        case let .error(error as LiftError): throw LiftError(error: error, key: self.key(), context: self)
        case let .error(error): throw error
        // If we don't explicty try to extract null and the value is null just return nil
        case .null where !(null is U): return nil
        default: return try f(self)
        }
    }
}

extension Jar {
    var contextDescription: String {
        switch object {
        case .none, .error:
            return ""
        default:
            do {
                return try String(json: self, prettyPrinted: false)//) ?? (self.toAny(context).map { "\($0)" } ?? "null")
            } catch let error as LiftError {
                return error.description
            } catch {
                return error.localizedDescription
            }
        }
    }
}

struct _Droppable: JarRepresentable {
    let any: Any
    
    var jar: Jar {
        return Jar(unchecked: any)
    }
}

/// Convert object hierarchy where all objects conform JarRepresentable to their "raw" prepresentation
private func convert(_ object: Any, context: Jar.Context) throws -> Any {
    switch object {
    case let val as Null:
        return val
    case let dictionary as [String: Any]:
        var dict = [String: Any]()
        for (key, value) in dictionary {
            dict[key] = try convert(value, context: context)
        }
        return dict as Any
    case let array as [Any]:
        return try array.map { try convert($0, context: context) }
    case let val as JarRepresentable:
        return try val.asJar(using: context).object.unwrap(context)
    default:
        throw LiftError("Value does not conform to JarRepresentable", key: "", context: { "\(object)" })
    }
}

private extension Jar {
    var optional: Jar? {
        if case .none = object { return nil }
        return self
    }
    
    func unwrap() throws -> Any {
        return try object.unwrap(context)
    }
    
    var objectName: String {
        if case .error = object { return "error" }
        do {
            guard let val = try object.asAny(context) else { return "nil" }
            return try val is Null ? "null" : "\((val as? Bool) ?? asAny() as Any)"
        } catch {
            return error.localizedDescription
        }
    }
}
