//
//  Jar+Dictionary.swift
//  Lift
//
//  Created by Måns Bernhardt on 2017-04-03.
//  Copyright © 2017 iZettle. All rights reserved.
//

import Foundation

public extension Jar {
    /// Returns the wrapped value if it's a dictionary and it is successfully converted
    var dictionary: [String: Any]? {
        return (try? object.asAny(context)) as? [String: Any]
    }
    
    /// Set the element at `key` to a value conforming to `JarRepresentable`
    /// - Note: Setting a value where `self` is not a dictionary will update the wrapped value to become a dictionry holding the value.
    /// - Note: The getter is typically never used. Instead use the subscript overload the returns a `Jar`
    /// - Note: To set an array, dictionary or optional, pass a `Jar` wrapping the valus such as `Jar(["key": 5])`
    subscript(key: String) -> JarRepresentable? {
        get {
            return dictionary?[key].map(_Droppable.init)
        }
        set {
            if let val = newValue {
                dictionaryAppend({ [ key: try val.asJar(using: $0).asAny() ] })
            } else {
                dictionaryAppend({ _ in [ key: Object.RemoveElement() ] })
            }
        }
    }
    
    /// Access the element at `key` and return it in a `Jar`
    /// When a value is lifted out of the jar it might throw if `self` is not a dictionary or if the key is missing and the lift is non-optional
    /// - Note: Setting a value where `self` is not a dictionary will update the wrapped to become a dictionry holding the value.
    /// - Note: The setter is typically never used. Instead use the subscript overload the takes a `JarRepresentable`
    subscript(key: String) -> Jar {
        get {
            let _key: () -> String = {
                let k = self.key()
                return k + (k.isEmpty ? "" : ".") + key
            }
            
            switch object {
            case .error, .none, .null:
                return Jar(object: object, context: context, key: self.key)
            case .dictionary:
                return Jar(object: Object(dictionary?[key]), context: context, key: _key)
            default:
                return Jar(object: .error(LiftError("Not a dictionary", key: "", context: self)), context: context, key: _key)
            }        }
        set {
            dictionaryAppend({ _ in [ key: try newValue.asAny() ] })
        }
    }
    
    
    /// Returns a new jar containing the union of self and `value`
    /// - Note: If both `self` and `value` contains the same key, `value`'s will be used
    func union(_ value: JarRepresentable) -> Jar {
        var new = self
        new.formUnion(value)
        return new
    }
    
    /// Updates self to be the union between self and `value`
    /// - Note: If both `self` and `value` contains the same key, `value`'s will be used
    mutating func formUnion(_ value: JarRepresentable) {
        dictionaryAppend({ try value.asJar(using: $0).asAny() })
    }
}

/// Lift a dictionary value out of a Jar
public postfix func ^<K: Liftable, V: Liftable>(jar: Jar) throws -> [K:V] where V.To == V, K.To == K, K: Hashable {
    let dictionary = try jar.assertNotNil(jar.dictionary, "Not a dictionary")
    let keys: [K] = try Jar(unchecked: Array(dictionary.keys)).union(context: jar.context)^
    let values: [V] = try Jar(unchecked: Array(dictionary.values)).union(context: jar.context)^
    var mappedDictionary = [K:V]()
    for (key, value) in zip(keys, values) {
        mappedDictionary[key] = value
    }
    return mappedDictionary
}

/// Lift an optional dictionary value out of a Jar
public postfix func ^<K: Liftable, V: Liftable>(jar: Jar) throws -> [K:V]? where V.To == V, K.To == K, K: Hashable {
    return try jar.map { try $0^ }
}

public extension Jar {
    /// Lifts a dictionary of type `[K:V]` and applies `transform` to it
    func map<K: Liftable, V: Liftable, O>(_ transform: ([K:V]) throws -> O) throws -> O where V.To == V, K.To == K {
        return try transform(self^)
    }
    
    /// Lifts a dictionary of type `[K:V]`, and if not nil, applies `transform` to it
    func map<K: Liftable, V: Liftable, O>(_ transform: ([K:V]) throws -> O) throws -> O? where V.To == V, K.To == K {
        return try map { try $0.map(transform) }
    }
}

private extension Jar {
    mutating func dictionaryAppend(_ toAny: @escaping ToAny) {
        switch object {
        case let .dictionary(dicts):
            object = .dictionary(dicts + [ toAny ])
        case .none:
            object = .dictionary([ toAny ])
        case let .primitive(val):
            object = .dictionary([ val, toAny ])
        default:
            object = .error(LiftError("Not a dictionary", context: self))
        }
    }
}

