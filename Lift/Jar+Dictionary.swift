//
//  Jar+Dictionary.swift
//  Lift
//
//  Created by Måns Bernhardt on 2017-04-03.
//  Copyright © 2017 PayPal Inc. All rights reserved.
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
                dictionaryAppend({ try val.asJar(using: $0).asAnyOptional().map { [ key: $0 ] } ?? [:] })
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
            let subscriptKey: () -> String = {
                let evaluatedKey = self.key()
                return evaluatedKey + (evaluatedKey.isEmpty ? "" : ".") + key
            }

            switch object {
            case .error, .none, .null:
                return Jar(object: object, context: context, key: self.key)
            case .dictionary:
                return Jar(object: Object(dictionary?[key]), context: context, key: subscriptKey)
            case .jarRepresentable(let jarRepresentable):
                return jarRepresentable.asJar(using: context)[key]
            case .array, .primitive:
                return Jar(object: .error(LiftError("Not a dictionary", key: "", context: self)), context: context, key: subscriptKey)
            }
        }
        set {
            dictionaryAppend({ _ in try newValue.asAnyOptional().map { [ key: $0] } ?? [:] })
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

private extension Jar {
    mutating func dictionaryAppend(_ toAny: @escaping ToAny) {
        switch object {
        case let .dictionary(dicts):
            object = .dictionary(dicts + [ toAny ])
        case .none:
            object = .dictionary([ toAny ])
        case let .primitive(val):
            object = .dictionary([ val, toAny ])
        case let .jarRepresentable(jarRepresentable):
            var jar = jarRepresentable.asJar(using: context)
            jar.dictionaryAppend(toAny)
            object = jar.object
        case .array, .error, .null:
            object = .error(LiftError("Not a dictionary", context: self))
        }
    }
}
