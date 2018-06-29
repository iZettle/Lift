//
//  Jar+Object.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

extension Jar {
    init(object: Object, context: Context = [], key: @escaping () -> String = { "" }) {
        self.object = object
        self.context = context
        self.key = key
    }

    /// Internal representation to avoid repetitive value conversions as well as handling error and absent states
    enum Object {
        case none(context: () -> String) /// Contains no value (nil), such as when subscripting using a key into a Jar return a Jar representing a absence of a value
        case null
        case primitive(ToAny) /// Typically Bool, Integer, Floating Point or String
        case dictionary([ToAny]) // an array of where all toAny much return a [String: Any] and will be applied left to right
        case array([(Range<Int>?, ToAny)]) // replace range with, unless range == nil where we should append. ToAny have to evaluate to [Any]
        case jarRepresentable(JarRepresentable)
        case error(Error) /// We already know something went wrong such as a conversion that will result in lifting the value out will throw.

        init(_ any: Any?) {
            switch any {
            case nil:
                self = .none(context: { "" })
            case is Null:
                self = .null
            case let dictionary as [String: Any]:
                self = .dictionary([ { _ in dictionary}])
            case let array as [Any]:
                self = .array([(nil, { context in array })])
            case let object?:
                self = .primitive { _ in object }
            }
        }

        /// Used by .dictionary mark removal of items.
        struct RemoveElement {}

        func optionallyUnwrap(_ context: Context) throws -> Any? {
            switch self {
            case .none: return nil
            case .null: return Lift.null
            case let .dictionary(toAnys):
                var result = [String: Any]()
                for toAny in toAnys {
                    let any = try toAny(context)
                    guard let dict = try toAny(context) as? [String: Any] else {
                        throw LiftError("Not a dictionary: \(any)")
                    }
                    for (key, val) in dict {
                        result[key] = val is RemoveElement ? nil : val
                    }
                }
                return result
            case let .array(ops):
                var result = [Any]()
                for (range, toAny) in ops {
                    let any = try toAny(context)
                    guard let array = any as? [Any] else {
                        throw LiftError("Not an array: \(any)")
                    }
                    if let range = range {
                        guard range.lowerBound >= result.startIndex && range.upperBound < result.endIndex else {
                            throw LiftError("Index out of bounds")
                        }
                        result.replaceSubrange(range, with: array)
                    } else {
                        result += array
                    }
                }
                return result
            case let .primitive(val):
                let value = try val(context)
                if let jar = value as? Jar {
                    return try jar.object.unwrap(context)
                } else {
                    return value
                }
            case let .jarRepresentable(jarRepresentable):
                let jar = jarRepresentable.asJar(using: context)
                return try jar.object.optionallyUnwrap(jar.context)
            case let .error(error):
                throw error
            }
        }

        func unwrap(_ context: Context) throws -> Any {
            if case let .none(context) = self {
                throw LiftError("Value missing", key: "", context: context)
            }
            return try optionallyUnwrap(context)!
        }

        func asAny(_ context: Context) throws -> Any? {
            if case .error = self { return nil }
            return try optionallyUnwrap(context)
        }
    }

    typealias ToAny = (Context) throws -> Any
}
