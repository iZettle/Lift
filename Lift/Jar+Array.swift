//
//  Jar+Array.swift
//  Lift
//
//  Created by Måns Bernhardt on 2017-04-03.
//  Copyright © 2017 PayPal Inc. All rights reserved.
//

import Foundation

public extension Jar {
    /// Returns the wrapped value if it's an array and it is successfully converted
    var array: [Any]? {
        return (try? object.asAny(context)) as? [Any]
    }

    /// Set the element at `index` to a value conforming to `JarRepresentable`
    /// - Note: Setting a value where `self` is not an array or if the index is out of bounds will trap.
    /// - Note: The getter is typically never used. Instead use the subscript overload that returns a `Jar`
    subscript(index: Int) -> JarRepresentable {
        get {
            return self[index] as Jar
        }
        set {
            arrayReplace(at: index, with: { try newValue.asJar(using: $0).asAnyOptional().map { [$0] } ?? [] })
        }
    }

    /// Extract the element at `index` and return it in a `Jar`
    /// When a value is lifted out of the returned jar it might throw if `self` is not an array or if the access was out of bounds.
    /// - Note: Setting a value where `self` is not an array or if the index is out of bounds will trap.
    /// - Note: The setter is typically never used. Instead use the subscript overload that takes a `JarRepresentable`
    subscript(index: Int) -> Jar {
        get {
            let key: () -> String = { self.key() + "[\(index)]" }

            switch object {
            case .error, .none, .null:
                return Jar(object: object, context: context, key: self.key)
            case .array:
                let array = self.array!
                guard index >= array.startIndex && index < array.endIndex else {
                    return Jar(object: .error(LiftError("Index out of bounds", key: "", context: self)), context: context, key: key)
                }
                return Jar(object: Object(array[index]), context: context, key: key)
            case .jarRepresentable(let jarRepresentable):
                return jarRepresentable.asJar(using: context)[index]
            case .dictionary, .primitive:
                return Jar(object: .error(LiftError("Not an array", key: "", context: self)), context: context, key: self.key)
            }
        }
        set {
            arrayReplace(at: index, with: { _ in try newValue.asAnyOptional().map { [$0] } ?? [] })
        }
    }

    /// Appends a `jar` to `self` if `self` is an array or set `self` to an array holding `jar` if not
    mutating func append(_ value: JarRepresentable) {
        arrayReplace(at: nil, with: { try value.asJar(using: $0).asAnyOptional().map { [$0] } ?? [] })
    }

    /// Appends a `jar` to `self` if `self` is an array or set `self` to an array holding `jar` if not
    mutating func append(_ jar: Jar) {
        append(jar as JarRepresentable)
    }
}

private extension Jar {
    mutating func arrayReplace(at range: Range<Int>?, with toAny: @escaping ToAny) {
        switch object {
        case let .array(ops):
            object = .array(ops + [ (range, toAny) ])
        case .none:
            object = .array([ (nil, toAny) ])
        case let .primitive(val):
            object = .array([ (nil, val), (nil, toAny) ])
        case let .jarRepresentable(jarRepresentable):
            var jar = jarRepresentable.asJar(using: context)
            jar.arrayReplace(at: range, with: toAny)
            object = jar.object
        case .dictionary, .error, .null:
            object = .error(LiftError("Not an array", context: self))
        }
    }

    mutating func arrayReplace(at index: Int, with toAny: @escaping ToAny) {
        arrayReplace(at: Range(uncheckedBounds: (index, index)), with: toAny)
    }
}
