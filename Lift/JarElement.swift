
//
//  JarElement.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// Class types conforming to `JarConvertible` can by lifted out of a `Jar` using the ^ operator
/// Value types are recommended to use the more convenient `JarConvertible` instead
public protocol Liftable {
    associatedtype To
    static func lift(from jar: Jar) throws -> To
}

/// Value types conforming to `JarConvertible` can by lifted out of a `Jar` using the ^ operator
public protocol JarConvertible: Liftable {
    /// Construct `Self` from the content of the `jar`
    init(jar: Jar) throws
}

public extension JarConvertible where Self == To {
    static func lift(from jar: Jar) throws -> Self {
        return try Self(jar: jar)
    }
}

/// Conforming types can be expressed as a `Jar`
public protocol JarRepresentable {
    /// Construct a `Jar` representing `self`
    var jar: Jar { get }
}

/// JarRepresentable & JarConvertible
public typealias JarElement = JarConvertible & JarRepresentable

/// If you need access to the `Jar.Context` to be represented as a Jar conform to this protocol instead of JarRepresentable
public protocol JarRepresentableWithContext: JarRepresentable {
    func asJar(using context: Jar.Context) -> Jar
}

public extension JarRepresentableWithContext {
    var jar: Jar {
        return asJar(using: [])
    }
}

public extension JarRepresentable {
    func asJar(using context: Jar.Context) -> Jar {
        if let ctxSelf = self as? JarRepresentableWithContext {
            return ctxSelf.asJar(using: context)
        }
        return jar.union(context: context)
    }
    
    func asJar(using contextValues: JarContextValue?...) -> Jar {
        return asJar(using: Jar.Context(contextValues))
    }
}


extension Optional: JarRepresentable where Wrapped: JarRepresentable {
    public var jar: Jar {
        switch self {
        case let val?:
            return Jar(val)
        case nil:
            return Jar()
        }
    }
}

extension Optional: Liftable where Wrapped: Liftable, Wrapped.To == Wrapped {
    public typealias To = Optional<Wrapped>
    public static func lift(from jar: Jar) throws -> Optional<Wrapped> {
        switch jar.object {
        case .none:
            return .none
        case .null where type(of: Wrapped.self) != type(of: Null.self):
            return .none
        case .jarRepresentable(let jarRepresentable):
            return try lift(from: jarRepresentable.jar)
        default:
            return try Wrapped.lift(from: jar)
        }
    }
}

extension Optional: JarConvertible where Wrapped: JarConvertible, Wrapped.To == Wrapped {
    public init(jar: Jar) throws {
        self = try Wrapped?.lift(from: jar)
    }
}


extension Array: JarRepresentable where Element: JarRepresentable {
    public var jar: Jar {
        return Jar(object: .array([ (nil, { context in
            try self.map { $0.asJar(using: context) }.compactMap {
                return try $0.object.optionallyUnwrap($0.context).flatMap { $0 }
            }
        })]))
    }
}

extension Array: Liftable where Element: Liftable, Element.To == Element {
    public typealias To = [Element]
    public static func lift(from jar: Jar) throws -> [Element] {
        return try jar.assertNotNil(jar.array, "Not an array").enumerated().map { i, any in
            let itemJar = Jar(object: Jar.Object(any), context: jar.context, key: { jar.key() + "[\(i)]" })
            return try Element.lift(from: itemJar)
        }
    }
}

extension Array: JarConvertible where Element: JarConvertible, Element.To == Element {
    public init(jar: Jar) throws {
        self = try [Element].lift(from: jar)
    }
}


extension Dictionary: JarRepresentable where Key: CustomStringConvertible, Value: JarRepresentable  {
    public var jar: Jar {
        return Jar(object: .dictionary([{ context in
            var result = [String: Any]()
            for (key, val) in self {
                result[key.description] = try val.asJar(using: context).object.optionallyUnwrap(context)
            }
            return result
            }]))
    }
}

extension Dictionary: Liftable where Key: Liftable, Value: Liftable, Key.To == Key, Value.To == Value {
    public typealias To = [Key: Value]
    public static func lift(from jar: Jar) throws -> [Key: Value] {
        let dictionary = try jar.assertNotNil(jar.dictionary, "Not a dictionary")
        let keys: [Key] = try Jar(unchecked: Array(dictionary.keys)).union(context: jar.context)^
        let values: [Value] = try Jar(unchecked: Array(dictionary.values)).union(context: jar.context)^
        var mappedDictionary = [Key: Value]()
        for (key, value) in zip(keys, values) {
            mappedDictionary[key] = value
        }
        return mappedDictionary
    }
}

extension Dictionary: JarConvertible where Key: JarConvertible, Value: JarConvertible, Key.To == Key, Value.To == Value {
    public init(jar: Jar) throws {
        self = try [Key: Value].lift(from: jar)
    }
}


