//
//  Jar+Expressible.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 PayPal Inc. All rights reserved.
//

import Foundation

extension Jar: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (CustomStringConvertible, JarRepresentable)...) {
        var dict = [String: Jar]()
        for (key, value) in elements {
            dict[key.description] = Jar(value)
        }
        self.init(dict)
    }
}

extension Jar: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JarRepresentable...) {
        object = .array([ (nil, { context in
            try elements.compactMap { try $0.asJar(using: context).object.optionallyUnwrap(context).flatMap { $0 } }
        })])
    }
}

extension Jar: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(object: .primitive(value.asJar))
    }
}

extension Jar: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self.init(object: .primitive(value.asJar))
    }
}

extension Jar: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(object: .primitive(value.asJar))
    }
}

extension Jar: ExpressibleByStringLiteral {
    public init(unicodeScalarLiteral value: String) {
        self.init(object: .primitive(value.asJar))
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(object: .primitive(value.asJar))
    }

    public init(stringLiteral value: String) {
        self.init(object: .primitive(value.asJar))
    }
}
