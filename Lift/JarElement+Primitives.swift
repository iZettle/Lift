//
//  JarElement+Primitives.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

extension String: JarConvertible, JarRepresentable {
    public init(jar: Jar) throws {
        switch try jar.asAny() {
        case let val as String: self = val
        case let val as NSNumber: self = val.description
        default: throw jar.assertionFailedToConvert(to: String.self)
        }
    }

    public var jar: Jar {
        return Jar(unchecked: self)
    }
}

extension NSString: JarRepresentable {
    public var jar: Jar {
        return Jar(unchecked: self)
    }
}

extension Bool: JarElement {
    public init(jar: Jar) throws {
        self = try jar.convert()
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Int: JarElement {
    public init(jar: Jar) throws {
        self = try jar.assertFitsIn(Int(exactly: jar.int64()))
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Int16: JarElement {
    public init(jar: Jar) throws {
        self = try jar.assertFitsIn(Int16(exactly: jar.int64()))
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Int32: JarElement {
    public init(jar: Jar) throws {
        self = try jar.assertFitsIn(Int32(exactly: jar.int64()))
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Int64: JarElement {
    public init(jar: Jar) throws {
        self = try jar.int64()
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Double: JarElement {
    public init(jar: Jar) throws {
        self = try jar.convert()
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension Float: JarElement {
    public init(jar: Jar) throws {
        self = try jar.convert()
    }

    public var jar: Jar {
        return Jar(unchecked: NSNumber(value: self))
    }
}

extension NSNumber: JarRepresentable {
    public var jar: Jar {
        switch self {
        case is NSDecimalNumber:
            return Jar(description) // use string representation to not lose precision
        default:
            return Jar(unchecked: self)
        }
    }
}

extension Null: Liftable, JarRepresentable {
    public static func lift(from jar: Jar) throws -> NSNull {
        switch try jar.asAny() {
        case let value as NSNull:
            return value
        default:
            throw jar.assertionFailure("Value not convertible to NSNull")
        }
    }

    public var jar: Jar {
        return Jar(unchecked: self)
    }
}

extension UUID: JarElement {
    public init(jar: Jar) throws {
        self = try jar.assertNotNil(UUID(uuidString: jar^), "Invalid UUID string")
    }

    public var jar: Jar {
        return Jar(uuidString)
    }
}

extension NSDecimalNumber: Liftable {
    public static func lift(from jar: Jar) throws -> NSDecimalNumber {
        switch try jar.asAny() {
        case let value as NSDecimalNumber:
            return value
        case let value as NSNumber:
            return NSDecimalNumber(string: value.description)
        case let value as String:
            return NSDecimalNumber(string: value)
        default:
            throw jar.assertionFailedToConvert(to: self)
        }
    }
}

public extension DateFormatter {
    @nonobjc static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
}

extension DateFormatter: JarContextValue {}

extension Date: JarConvertible, JarRepresentableWithContext {
    public init(jar: Jar) throws {
        let formatter: DateFormatter = jar.context.get() ?? .iso8601
        self = try jar.assertNotNil(formatter.date(from: jar^), "Date failed to convert using formatter with dateFormat: \(formatter.dateFormat ?? "nil")")
    }

    public func asJar(using context: Jar.Context) -> Jar {
        let formatter: DateFormatter = context.get() ?? .iso8601
        return Jar(formatter.string(from: self))
    }
}

extension URL: JarElement {
    public init(jar: Jar) throws {
        self = try jar.assertNotNil(URL(string: jar^), "Invalid URL")
    }

    public var jar: Jar {
        return Jar(absoluteString)
    }
}

public extension RawRepresentable where Self: JarElement, RawValue: JarElement, RawValue == RawValue.To {
    init(jar: Jar) throws {
        let value: RawValue = try jar^
        self = try jar.assertNotNil(Self(rawValue: value), "Could not find case matching raw value \(value) for enum \(Self.self)")
    }

    var jar: Jar {
        return Jar(rawValue)
    }
}

private extension Jar {
    func convert<T>() throws -> T {
        guard let val = try (asAny() as? T) else {
            throw jar.assertionFailedToConvert(to: T.self)
        }
        return val
    }
}

// Should be updated when new Swift Integers have been released.
private extension Jar {
    func int64() throws -> Int64 {
        switch try asAny() {
        case let value as Int:
            return Int64(value)
        case let value as Int64:
            return value
        case let value as NSNumber:
            guard let number = Int64(value.stringValue) else { throw assertionFailedToConvert(to: type(of: Int64.self)) }
            return number
        case let value as String:
            guard let number = Int64(value) else { throw assertionFailedToConvert(to: type(of: Int64.self)) }
            return number
        default:
            throw assertionFailedToConvert(to: type(of: Int64.self))
        }
    }
}

private extension Jar {
    func assertionFailedToConvert<T>(to type: T.Type) -> LiftError {
        return assertionFailure("Value `\(contextDescription)` is not convertible to \(type)")
    }

    func assertFitsIn<T>(_ val: T?) throws -> T {
        return try assertNotNil(val, "Value `\(contextDescription)` does not fit in \(T.self)")
    }
}
