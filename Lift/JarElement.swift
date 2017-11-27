
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

 
