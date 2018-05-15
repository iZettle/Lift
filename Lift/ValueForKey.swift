//
//  ValueForKey.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

/// Abstracts the access of `Any` for a `key`
/// Conforming types such `UserDefaults`' will allow lifting values out of them:
///
///     let value: Int = UserDefaults.standard["value"]^
public protocol ValueForKey {
    func value(forKey key: String) -> Any?
}

/// Abstracts the mutable access of `Any` for a `key`
/// Use this allow lifting and dropping of values out and into types such as UserDefaults
///
///     UserDefaults.standard["value"] = 5
public protocol MutatingValueForKey: ValueForKey {
    mutating func set(_ value: Any?, forKey key: String)
}

public extension ValueForKey {
    subscript(key: String) -> JarRepresentable? {
        return value(forKey: key).map(_Droppable.init)
    }
}

public extension MutatingValueForKey {
    subscript(key: String) -> JarRepresentable? {
        get { return value(forKey: key).map(_Droppable.init) }
        set { try! set(newValue?.asJar(using: []).asAny(), forKey: key) }
    }
}

public extension MutatingValueForKey where Self: AnyObject {
    subscript(key: String) -> JarRepresentable? {
        get { return value(forKey: key).map(_Droppable.init) }
        nonmutating set {
            var s = self
            try! s.set(newValue?.asJar(using: []).asAny(), forKey: key)
        }
    }
}

public extension ValueForKey {
    subscript(key: String) -> Jar {
        return Jar(object: Jar.Object(value(forKey: key)), key: { key })
    }
}

public extension MutatingValueForKey {
    subscript(key: String) -> Jar {
        get { return Jar(object: Jar.Object(value(forKey: key)), key: { key }) }
        set { try! set(newValue.asAny(), forKey: key) }
    }
}

public extension MutatingValueForKey where Self: AnyObject {
    subscript(key: String) -> Jar {
        get { return Jar(object: Jar.Object(value(forKey: key)), key: { key }) }
        nonmutating set {
            var s = self
            try! s.set(newValue.object.asAny([]), forKey: key)
        }
    }
}
