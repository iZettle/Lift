//
//  IntegerTests.swift
//  Lift
//
//  Created by Mattias Jähnke on 2017-05-10.
//  Copyright © 2017 iZettle. All rights reserved.
//

import XCTest
import Lift

class IntegerTests: XCTestCase {
    func testInteger() throws {
        let maxInteger: Int = try Jar(Int.max)^
        XCTAssertEqual(maxInteger, Int.max)
    }

    func testOverflowingInt16() throws {
        let overflowInt: Int32 = Int32(Int16.max) + 1
        XCTAssertThrows(try Jar(overflowInt)^ as Int16)
        XCTAssertEqual(try Jar(overflowInt)^ as Int32, overflowInt)
        XCTAssertEqual(try Jar(overflowInt)^ as Int64, Int64(overflowInt))
    }

    func testOverflowingInteger32() throws {
        let overflowInt: Int64 = Int64(Int32.max) + 1
        XCTAssertThrows(try Jar(overflowInt)^ as Int16)
        XCTAssertThrows(try Jar(overflowInt)^ as Int32)
        XCTAssertEqual(try Jar(overflowInt)^ as Int64, overflowInt)
    }
}
