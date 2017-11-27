//
//  Jar+Additions.swift
//  Lift
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import Foundation

public extension Data {
    /// Construct a JSON string `Data` from a `Jar`
    init(json jar: Jar, prettyPrinted: Bool = true) throws {
        let any = try jar.asAny()
        
        if any is [Any] || any is [String: Any] {
            self = try JSONSerialization.data(withJSONObject: try jar.asAny(), options: prettyPrinted ? .prettyPrinted : [])
        } else if any is Null {
            self = try jar.assertNotNil("null".data(using: .utf8))
        } else if let n = any as? NSNumber, String(cString: n.objCType) == "c" {
            self = try jar.assertNotNil("\((any as? Bool) ?? any)".data(using: .utf8))
        } else {
            self = try jar.assertNotNil("\(any)".data(using: .utf8))
        }
    }
}

public extension String {
    /// Construct a JSON `String` from a `Jar`
    init(json jar: Jar, prettyPrinted: Bool = true) throws {
        let data = try Data(json: jar, prettyPrinted: prettyPrinted)
        self = try jar.assertNotNil(String(data: data, encoding: .utf8))
    }
}

public extension Jar {
    /// Construct a `Jar` from the content of the `json` data
    init(json data: Data) throws {
        try self.init(unchecked: JSONSerialization.jsonObject(with: data, options: .allowFragments))
    }
    
    /// Construct a `Jar` from the content of the `json` string
    init(json string: String) throws {
        try self.init(json: string.data(using: String.Encoding.utf8).assertNotNil("Not an UTF8 string"))
    }
    
    /// Construct a `Jar` from the JSON at `url`
    init(json url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(json: data)
    }
}

extension Jar: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        do {
            return try String(json: self, prettyPrinted: true)
        } catch {
            return error.localizedDescription
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

extension UserDefaults: MutatingValueForKey { }
