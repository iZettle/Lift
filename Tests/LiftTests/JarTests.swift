//
//  JarTests.swift
//  JarTests
//
//  Created by Måns Bernhardt on 2016-05-23.
//  Copyright © 2016 iZettle. All rights reserved.
//

import XCTest
import Lift
import Foundation

class JarTests: XCTestCase {
    func testInteger() throws {
        let original = 4711
        let value = Jar(original)
        
        let i1: Int = try value^
        XCTAssertEqual(i1, original)

        let i2: Int? = try value^
        XCTAssertEqual(i2, original)
        
        let i3 = try value^ as Int
        XCTAssertEqual(i3, original)

        let i4: Int = try value.map { $0 * 2 }
        XCTAssertEqual(i4, original*2)

        XCTAssertEqual(try value^ as Int, original)
        XCTAssertEqual(try (value^ as Int) * 2, original*2)
        
        
        var json: Jar = [ "val": original, "dict": [ "sub": 44 ] as Jar ]
        
        let i5: Int = try json["val"]^
        XCTAssertEqual(i5, original)
        
        json["val"] = 88
        let i52: Int = try json["val"]^
        XCTAssertEqual(i52, 88)

        let i6: Int = try json["dict"]["sub"]^
        XCTAssertEqual(i6, 44)

        json["dict"]["sub"] = 55
        let i7: Int = try json["dict"]["sub"]^
        XCTAssertEqual(i7, 55)
    }
    
    func testDate() throws {
        let original = try! fromIso8601("2016-05-23T10:35:52.046+02:00")
        let value = Jar(original)
        
        let d1: Date = try value^
        XCTAssertEqual(d1, original)
        let d2: Date = try value.map(fromIso8601)
        XCTAssertEqual(d2, original)
        
        var json: Jar = ["date": original]
        let d3: Date = try json["date"]^
        XCTAssertEqual(d3, original)

        let date = try! fromIso8601("2016-04-23T10:32:52.046+02:00")
        json["date"] = date
        let d4: Date = try json["date"]^
        XCTAssertEqual(d4, date)

        json["date"] = date.asIso8601
        let d5: Date = try json["date"]^
        XCTAssertEqual(d5, date)
    }
    
    func testDecimalNumber() throws {
        let d = NSDecimalNumber(string: "123456789.123456789")
        let j = Jar(["amount": d])
        let json = try String(json: j, prettyPrinted: false)
        XCTAssertEqual(json, "{\"amount\":\"123456789.123456789\"}")
        
        let d2: NSDecimalNumber = try j["amount"]^
        XCTAssertEqual(d, d2)
    }

    func testURL() throws {
        let jar = Jar("http://izettle.com")
        let url = try jar.assertNotNil(URL(string: jar^), "Invalid URL")

        let _: URL = try jar^
        
        XCTAssertThrows(try Jar("http://\\//izettle.com")^ as URL, isValidError: path(""))
        
        XCTAssertEqual(Jar(url).description, "http://izettle.com")
    }

    struct Test: JarElement {
        var val: Int = 47
        
        init() {}
        
        init(jar: Jar) throws {
            try val = jar["val"]^
        }
        
        var jar: Jar {
            return ["val": val]
        }
    }
    
    func testStruct() throws {
        var json: Jar = ["test": Test()]
        let t1: Test = try json["test"]^
        XCTAssertEqual(t1.val, 47)
        
        json["test"]["val"] = 53

        let t2: Test = try json["test"]^
        XCTAssertEqual(t2.val, 53)


        let testsJson: Jar = [ Test(), Test() ]
        let tests: Array = try testsJson.map { try Test(jar: $0) }
        XCTAssertEqual(tests[0].val, 47)
    }
    
    func testJar() throws {
        let l1 = Jar(5)
        
        let i1: Int = try l1^
        XCTAssertEqual(i1, 5)

        let l2 = Jar(["value": 8])
        
        let i2: Int = try l2["value"]^
        XCTAssertEqual(i2, 8)

        let l3 = Jar([7, 8, 9])
        
        let i3: Int = try l3[2]^
        XCTAssertEqual(i3, 9)
        
        var json = Jar()
        json["date"] = Date()
        json["val"] = 5
        XCTAssertEqual(try json["val"]^ as Int, 5)

        var json2 = Jar()
        json2.append(Date())
        json2.append(5)
        XCTAssertEqual(try json2[1]^ as Int, 5)

        func log(_ json: Jar) {
            var _json = json
            _json["password"] = nil
            print(_json)
        }
        
    }
    
    func testArray() throws {
        let l1 = Jar([5, 2, 3, 4])
        let a1: [Int] = try l1^
        XCTAssertEqual(a1[2], 3)

        let l2: Jar = [5, 2, 3, 4]
        let a2: [Int] = try l2^
        XCTAssertEqual(a2[3], 4)

        var l3: Jar = [5, 2, 3, 4]
        let a3: [Int] = try l3^
        XCTAssertEqual(a3[0], 5)

        l3[2] = 7
        let a33: [Int] = try l3^
        XCTAssertEqual(a33[2], 7)

        let json: Jar = ["key": Jar([ Jar(["val" : 1]), Jar(["val" : 2]) ])]
        
        let i1: Int = try json["key"][0]["val"]^
        XCTAssertEqual(i1, 1)
        var json2 = json
        json2["key"][0]["val"]  = 48
        let i2: Int = try json2["key"][0]["val"]^
        XCTAssertEqual(i2, 48)

        let a4: Jar = ["1", "2"]
        let i2s: [Int] = try a4.map { try Int($0).assertNotNil() }
        XCTAssertEqual(i2s[1], 2)

        let i3s: [Int] = try a4.map { try Int($0).assertNotNil() } ?? []
        XCTAssertEqual(i3s[0], 1)

        let i4s: [Int] = try json["missing"].map { try Int($0).assertNotNil() } ?? [4, 5]
        XCTAssertEqual(i4s[0], 4)
    }
    
    func testDictionary() throws {
        do {
            let j1 = Jar(["1": 1, "2": 2, "3": 3])
            
            let v1: [String: Int] = try j1^
            XCTAssertEqual(v1["1"], 1)
            let v2: [String: Double]? = try j1^
            XCTAssertEqual(v2?["1"], 1.0)
            
            func sortTuple<T, U>(lhs: (T, U), rhs: (T, U)) -> Bool where T: Comparable {
                return lhs.0 < rhs.0
            }
            let v3: [(String, String)] = try j1.map { $0.map { $0 }.sorted(by: sortTuple) }
            XCTAssertTrue(v3.sorted(by: sortTuple)[1] == ("2", "2"))
            
            let v4: [(String, Bool)]? = try j1.map { $0.map { $0 }.sorted(by: sortTuple) }
            XCTAssertTrue(v4![2] == ("3", true))
            
            let v5: [Int: String] = try j1^
            XCTAssertEqual(v5[3], "3")

        } catch {
            print(error)
        }
    }
    
    func testMapTuple() throws {
        let jar: Jar = ["name": "Adam", "age": 25]
        typealias NameAndAge = (name: String, age: Int)
        let nameAndAge: NameAndAge = try jar.map { (jar: Jar) in try (jar["name"]^, jar["age"]^) }
        XCTAssertEqual(nameAndAge.name, "Adam")
        XCTAssertEqual(nameAndAge.age, 25)
    }

    
    func testUserDefaults() throws {
        UserDefaults.standard["test"] = 4711
        let i: Int = try UserDefaults.standard["test"]^
        XCTAssertEqual(i, 4711)
        UserDefaults.standard["test"] = "Hello"
        let s: String = try UserDefaults.standard["test"]^
        XCTAssertEqual(s, "Hello")
        
        UserDefaults.standard["test"] = nil
        UserDefaults.standard["test"] = Jar([1, 2, 4])
        UserDefaults.standard["test"] = [1, 2, 4]
        
        print(UserDefaults.standard.object(forKey: "test") as Any)
        
        UserDefaults.standard["test"] = Jar(["obj": Jar(["val": 4])])
        let i2: Int = try UserDefaults.standard["test"]["obj"]["val"]^
        XCTAssertEqual(i2, 4)


//        let n = NSNotification(name: "Test", object: nil, userInfo: ["val": 45])
//        let ni: Int = try n["val"]^
//        XCTAssertEqual(ni, 45)
        
    }
    
    func testHeterogenous() throws {
        let l1: Jar = try Jar(["val": 1])^
        let l2: Jar = try Jar(1)^
        let l3: Jar = try Jar([1, 2])^
        XCTAssertEqual(try l1["val"]^, 1)
        XCTAssertEqual(try l2^, 1)
        XCTAssertEqual(try l3^, [1, 2])
        
        XCTAssertThrows { let _: Int? = try l2["val"]^ }
        XCTAssertThrows { let _: Int? = try l2[3]^ }
        XCTAssertThrows { let _: Int? = try l3[3]^ }

        let date = try! fromIso8601("2016-05-23T10:35:52.046+02:00")
        let l5: Jar = [2, date, "String", NSNull()]
        let v1: Int = try l5[0]^
        let v2: Date = try l5[1]^
        let v3: String = try l5[2]^
        let v4: NSNull = try l5[3]^
        let v5: Int? = try l5[3]^
        XCTAssertEqual(v1, 2)
        XCTAssertEqual(v2, date)
        XCTAssertEqual(v3, "String")
        XCTAssertEqual(v4, NSNull())
        XCTAssertNil(v5)

        let json = Jar(5.5)
        if let int: Int = try? json^ {
            XCTAssertEqual(int, 5)
        } else if let ints: [Int] = try? json^ {
            XCTAssertEqual(ints[0], 4)
        } else if let int: Int = try? json["value"]^ {
            XCTAssertEqual(int, 4)
        }
        
        print(try String(json: [5, ["val", [1, 2] as Jar] as Jar, Jar([2, 4])], prettyPrinted: false) as Any)
    }
    
    enum MyEnum: String, JarElement {
        case one, two, three
    }
    
    func testEnum() throws {
        let json: Jar = ["enum": MyEnum.two]
        let str: String = try json["enum"]^
        XCTAssertEqual(str, "two")
        let e: MyEnum = try json["enum"]^
        XCTAssertEqual(e, MyEnum.two)
    }
    
    func testNull() throws {
        var json: Jar = ["val": null]
        
        let str: String? = try json["val"]^
        XCTAssertNil(str)

        let null1: Null = try json["val"]^
        XCTAssertEqual(null1, null)

        json["val"] = nil
        let null2: Null? = try json["val"]^
        XCTAssertNil(null2)

        json["val"] = null
        let null3: Null? = try json["val"]^
        XCTAssertEqual(null3, null)

        let o1: Int? = 5
        let o2: Int? = nil
        let json2: Jar =  ["val1": Jar(o1), "val2": Jar(o2)]
        let null4: Int = try json2["val1"]^
        XCTAssertEqual(null4, 5)
        let null5: Int? = try json2["val2"]^
        XCTAssertNil(null5)

        do {
            let json3: Jar = [Jar(o2), Jar(o1), Jar(o2)]
            let null6: Int = try json3[0]^
            XCTAssertEqual(null6, 5)
            XCTAssertThrows(try json3[1]^ as Int)
            let ints: [Int] = try json3^
            XCTAssertEqual(ints.count,  1)
        }
        
        do {
            let json3: Jar = [Jar(o2), Jar(o1), Jar(o2), null]
            let null6: Int = try json3[0]^
            XCTAssertEqual(null6, 5)
            let null7: Int? = try json3[1]^
            XCTAssertNil(null7)
            let null8: Null = try json3[1]^
            XCTAssertEqual(null8, null)

            XCTAssertThrows(try json3[1]^ as Int)
            let ints: [Jar] = try json3^
            XCTAssertEqual(ints.count,  2)
        }
        
        do {
            let json3: Jar = [Jar(o2), Jar(o1), Jar(o2), Jar(null)]
            let null6: Int = try json3[0]^
            XCTAssertEqual(null6, 5)
            XCTAssertThrows(try json3[1]^ as Int)
            let ints: [Jar] = try json3^
            XCTAssertEqual(ints.count,  2)
        }
        
        let _: Null = try Jar(["val": null])["val"]^
        
        if let _: Null = try? Jar(["val": 1])["val"]^ {
            XCTAssert(false)
        } else {
            XCTAssert(true)
        }

        if let _: Null = try? Jar(["val": null])["val"]^ {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
    
    func testLiterals() throws {
        var jsons = [Jar]()
        func send(_ jar: Jar) {
            jsons.append(jar)
        }
        
//        send(nil)
        send(true)
        send(1)
        send(3.14)
        send("Hello")
        send(["val", 5])
        send([1, 2, 3])
        
        let json = Jar(jsons)
        print(json)
    }

    func testLiteralsWithAppend() throws {
        var json: Jar = []
        json.append(null)
        json.append(true)
        json.append(1)
        json.append(3.14)
        json.append("Hello")
        json.append(["val", 5])
        json.append([1, 2, 3])
        print(try String(json: json, prettyPrinted: false) as Any)
        print(json)
    }

    func testUnion() throws {
        let jarA: Jar = ["val": 5, "val2": true]
        let jarB: Jar = ["val": 6, "val3": "Hello"]
        let union = jarA.union(jarB)
        XCTAssertEqual(try union["val"]^, 6)
        XCTAssertEqual(try union["val2"]^, true)
        XCTAssertEqual(try union["val3"]^, "Hello")
        
        var union2 = jarB
        union2.formUnion(jarA)
        XCTAssertEqual(try union2["val"]^, 5)
        XCTAssertEqual(try union2["val2"]^, true)
        XCTAssertEqual(try union2["val3"]^, "Hello")
    }
    
    func testIntegerBitSizes() throws {
        let jar: Jar = 4711
        let i: Int = try jar^
        let i16: Int16 = try jar^
        let i32: Int32 = try jar^
        let i64: Int64 = try jar^
        _ = Jar(i)
        _ = Jar(i16)
        _ = Jar(i32)
        _ = Jar(i64)
    }

    func testErrorKeyPath() {
        let jar: Jar = ["val": 5, "val2": Jar(["val3": 3]), "val4": Jar([1, 2, Jar([3, 4])]), "test": Test(), "tests": Jar([Test(), Test()])]

        XCTAssertThrows(try jar["val4"]^ as String, isValidError: path("val4"))
        XCTAssertThrows(try jar["val4"]^ as Bool, isValidError: path("val4"))
        XCTAssertThrows(try jar["val4"]^ as Null, isValidError: path("val4"))
        XCTAssertThrows(try jar["val4"]^ as URL, isValidError: path("val4"))

        XCTAssertThrows(try jar["value"]^ as Date, isValidError: path("value"))
        XCTAssertThrows(try jar["val"]^ as Date, isValidError: path("val"))
        XCTAssertThrows(try jar["val"].map { $0 + 1 } as Date, isValidError: path("val"))
        XCTAssertThrows(try jar["val2"]["value"]^ as Date, isValidError: path("val2.value"))
        XCTAssertThrows(try jar["val2"]["val3"]^ as Date, isValidError: path("val2.val3"))
        XCTAssertThrows(try jar["val4"][1]^ as Date, isValidError: path("val4[1]"))
        XCTAssertThrows(try jar["val4"][4]^ as Date, isValidError: path("val4[4]"))
        XCTAssertThrows(try jar["val4"][2][0]^ as Date, isValidError: path("val4[2][0]"))
        XCTAssertThrows(try jar["val4"][2][3]^ as Date, isValidError: path("val4[2][3]"))
        XCTAssertThrows(try jar["test"]["missing"]^ as Date, isValidError: path("test.missing"))
        XCTAssertThrows(try jar["test"]["val"]^ as Date, isValidError: path("test.val"))
        XCTAssertThrows(try jar["tests"][1]["missing"]^ as Date, isValidError: path("tests[1].missing"))
        XCTAssertThrows(try jar["tests"][1]["val"]^ as Date, isValidError: path("tests[1].val"))

        XCTAssertThrows(try jar["val"]^ as Date?, isValidError: path("val"))
        XCTAssertThrows(try jar["val2"]["val3"]^ as Date?, isValidError: path("val2.val3"))
        XCTAssertThrows(try jar["val4"][1]^ as Date?, isValidError: path("val4[1]"))
        XCTAssertThrows(try jar["val4"][4]^ as Date?, isValidError: path("val4[4]"))
        XCTAssertThrows(try jar["val4"][2][0]^ as Date?, isValidError: path("val4[2][0]"))
        XCTAssertThrows(try jar["val4"][2][3]^ as Date?, isValidError: path("val4[2][3]"))

        XCTAssertThrows(try jar["value"]^ as [Date], isValidError: path("value"))
        XCTAssertThrows(try jar["val"]^ as [Date], isValidError: path("val"))
        XCTAssertThrows(try jar["val2"]["value"]^ as [Date], isValidError: path("val2.value"))
        XCTAssertThrows(try jar["val2"]["val3"]^ as [Date], isValidError: path("val2.val3"))
        XCTAssertThrows(try jar["val4"][1]^ as [Date], isValidError: path("val4[1]"))
        XCTAssertThrows(try jar["val4"][4]^ as [Date], isValidError: path("val4[4]"))
        XCTAssertThrows(try jar["val4"][2][0]^ as [Date], isValidError: path("val4[2][0]"))
        XCTAssertThrows(try jar["val4"][2][3]^ as [Date], isValidError: path("val4[2][3]"))
        XCTAssertThrows(try jar["val4"][2]^ as [Date], isValidError: path("val4[2][0]"))
        XCTAssertThrows(try jar["tests"][1]["missing"]^ as [Date], isValidError: path("tests[1].missing"))
        XCTAssertThrows(try jar["tests"][1]["val"]^ as [Date], isValidError: path("tests[1].val"))
        
        
        let arrayJar: Jar = [1, 2]
        XCTAssertThrows(try arrayJar^ as [Date], isValidError: path("[0]"))
        XCTAssertThrows(try arrayJar^ as [Date]?, isValidError: path("[0]"))
        XCTAssertThrows(try arrayJar.map { $0 } as [Date], isValidError: path("[0]"))
        XCTAssertThrows(try arrayJar.map { $0 } as [Date]?, isValidError: path("[0]"))

        
        XCTAssertThrows(isValidError: path("val")) {
            let _: Date = try jar["val"].map { (_: Int) -> Date in throw LiftError("Custom Error") }
            return
        }

        var jar1 = jar
        jar1["tests"].append(["f": 1])
        XCTAssertThrows(isValidError: path("tests[2].val")) {
            let _: [Test] = try jar1["tests"].map { try Test(jar: $0) }
            return
        }

        XCTAssertThrows(isValidError: path("tests[2].val")) {
            let jars: [Jar] = try jar1["tests"]^
            let _: Int = try jars[2]["val"]^
            return
        }
        
        XCTAssertThrows(isValidError: path("tests[2].val")) {
            let _: [Test]? = try jar1["tests"].map { try Test(jar: $0) }
            return
        }
        
        XCTAssertThrows(isValidError: path("tests[2].val")) {
            let jars: [Jar]? = try jar1["tests"]^
            let _: Int = try jars![2]["val"]^
            return
        }
        
        XCTAssertThrows(isValidError: path("val")) {
            let _: [String: Int] = try jar1["val"]^
        }

        XCTAssertThrows(isValidError: path("val")) {
            let _: [String: Int]? = try jar1["val"]^
        }

        XCTAssertThrows(isValidError: path("val")) {
            let _: String = try jar1["val"].map { $0[2]! }
        }

        XCTAssertThrows(isValidError: path("val")) {
            let _: Int? = try jar1["val"].map { $0[2]! }
        }
        
        XCTAssertThrows(isValidError: path("tests[1]")) {
            throw jar1["tests"][1].assertionFailure()
        }

        let jar2: Jar = jar1["tests"]
        XCTAssertThrows(isValidError: path("tests")) {
            throw jar2.assertionFailure()
        }

        XCTAssertThrows(isValidError: path("tests[1]")) {
            throw jar2[1].assertionFailure()
        }
    }
    
    func testJSONDeserialization() throws {
        let dictJar = try Jar(json: "{ \"val\": 3, \"vals\": [ 1, 2 ] }")
        XCTAssertEqual(try dictJar["val"]^, 3)
        XCTAssertEqual(try dictJar["vals"]^, [1, 2])

        let arrayJar = try Jar(json: "[ 1, 2 ]")
        XCTAssertEqual(try arrayJar^, [1, 2])
        XCTAssertEqual(try arrayJar[0]^, 1)

        let boolJar = try Jar(json: "true")
        XCTAssertEqual(try boolJar^, true)
    }

    func testJSONSserialization() throws {
        XCTAssertEqual(Jar(true).description, "true")
        XCTAssertEqual(Jar(4711).description, "4711")
        XCTAssertEqual(Jar(47.11).description, "47.11")
        XCTAssertEqual(Jar(null).description, "null")
        XCTAssertEqual(Jar("Hello").description, "Hello")
        XCTAssertEqual(try String(json: Jar([1, 2]), prettyPrinted: false), "[1,2]")
        try XCTAssertEqual(String(json: Jar(["val": 2]), prettyPrinted: false), "{\"val\":2}")
        
        var jar: Jar = true
        XCTAssertEqual(jar.description, "true")
        jar = false
        XCTAssertEqual(jar.description, "false")
        jar = [1, 2]
        try XCTAssertEqual(String(json: jar, prettyPrinted: false), "[1,2]")
        jar["val"] = 1
        XCTAssertThrows(try String(json: jar, prettyPrinted: false)) // Can't set with key on array
        jar = ["val2": 2]
        try XCTAssertEqual(String(json: jar, prettyPrinted: false), "{\"val2\":2}")
        jar = 4711
        XCTAssertEqual(jar.description, "4711")
        jar = 47.25
        XCTAssertEqual(jar.description, "47.25")
        jar = "Hello"
        XCTAssertEqual(jar.description, "Hello")
        
    }
    
    func testChecked() throws {
        try XCTAssertEqual(Jar(checked: 2).description, "2")
        try XCTAssertEqual(String(json: Jar(checked: ["val": 2]), prettyPrinted: false), "{\"val\":2}")
        XCTAssertThrows(try Jar(checked: ["val", JarTests()]))
    }

    func testUnchecked() throws {
        XCTAssertEqual(Jar(unchecked: 2).description, "2")
        try XCTAssertEqual(String(json: Jar(unchecked: ["val": 2]), prettyPrinted: false), "{\"val\":2}")
        XCTAssertThrows { let _: Int = try Jar(unchecked: ["val": JarTests()])["val"]["int"]^ }
        XCTAssertThrows { let _: Int = try Jar(unchecked: ["val", JarTests()])["val"]["int"]^ }
    }
    
    func testPayment() throws {
        do {
            let json = "[{\"amount\": 1000, \"date\": \"2016-05-23T10:35:52.0+02:00\"}, {\"amount\": 200, \"date\": \"2016-05-25T12:10:22.0+02:00\"}]"
            
            let jar = try Jar(json: json)
            
            var payments: [Payment] = try jar^
            payments[1].date = Date()
            
            let newJson = try String(json: Jar(payments), prettyPrinted: true)
            print(newJson)
        } catch {
            print(error)
            throw error
        }
    }
    
    func testUser() throws {
        do {
            let json = "[{\"name\": \"Adam\", \"age\": 25}, {\"name\": \"Eve\", \"age\": 20}]"
            
            let jar = try Jar(json: json)
            
            var users: [User] = try jar^
            users.append(User(name: "Junior", age: 2))
            
            let newJson = try String(json: Jar(users), prettyPrinted: true)
            print(newJson)
        } catch {
            print(error)
            throw error
        }
    }
    
    func testAsDictionary() throws {
        let jar: Jar = ["a": 1, "b": 1.1, "c": "1", "d": "1.1", "e": "str"]
        let d = jar.dictionary!
        XCTAssert(d["a"] is Int)
        XCTAssert(d["b"] is Double)
        XCTAssert(d["c"] is String)
        XCTAssert(d["d"] is String)
        XCTAssert(d["e"] is String)
    }
    
    func testJarContext() throws {
        var jar = Jar(5)
        XCTAssertThrows(try jar^ as NeedContextType)
        XCTAssertThrows(try jar.union(context: MyContext(8))^ as NeedContextType)
        let _:  NeedContextType = try jar.union(context: MyContext())^
        jar.context.formUnion(MyContext())
        let _: NeedContextType = try jar^

        jar = Jar(NeedContextType())
        
        XCTAssertThrows(try String(json: jar))
        print(try String(json: jar.union(context: MyContext())))
    }
    
    func testSetsJarContext() throws {
        var jar = Jar(5)
        let _: SetsContextType = try jar.union(context: MyContext())^
        let _: SetsContextType = try jar.union(context: MyContext(8))^

        jar = Jar(SetsContextType())
        print(try String(json: jar))
        print(try String(json: jar.union(context: MyContext(8))))
    }
    
    func testJarArrayContext() throws {
        let jar = Jar([SetsContextType(), SetsContextType()])
        print(try String(json: jar))
    }
}

struct MyContext: JarContextValue {
    static let `default` = 4
    let value: Int
    init(_ val: Int = MyContext.default) { value = val }
}

struct NeedContextType {
    var value: Int = 4711
}

extension NeedContextType: JarRepresentableWithContext, JarConvertible {
    init(jar: Jar) throws {
        try jar.assert((try jar.context.get() as MyContext).value == MyContext.default)
        value = try jar^
    }
    
    func asJar(using context: Jar.Context) -> Jar {
        let myCtx: MyContext? = context.get()
        guard myCtx != nil else { return Jar(error: LiftError("Missing context")) }
        return Jar(value)
    }
}

struct SetsContextType {
    var value = NeedContextType()
}

extension SetsContextType: JarElement {
    init(jar: Jar) throws {
        let jar = jar.union(context: MyContext())
        value = try jar^
    }
    
    var jar: Jar {
        let jar = Jar(value)
        return jar.union(context: MyContext())
    }
}



struct Money {
    let fractionized: Int
}

extension Money: JarElement {
    init(jar: Jar) throws {
        fractionized = try jar^
    }
    
    var jar: Jar { return Jar(fractionized) }
}

struct Payment {
    var amount: Money
    var date: Date
}

extension Payment: JarElement {
    init(jar: Jar) throws {
        amount = try jar["amount"]^
        date = try jar["date"]^
    }
    
    var jar: Jar {
        return ["amount": amount, "date": date]
    }
}


struct User {
    let name: String
    let age: Int
}

extension User: JarElement {
    init(jar: Jar) throws {
        name = try jar["name"]^
        age = try jar["age"]^
    }
    
    var jar: Jar {
        return ["name": name, "age": age]
    }
}



func XCTAssertThrows<T>(_ message: String = "", file: StaticString = #file, line: UInt = #line, isValidError: ((Error) -> Bool)? = nil, expression: () throws -> T) {
    do {
        _ = try expression()
        XCTFail("No error to catch! - \(message)", file: file, line: line)
    } catch {
        print("Error:", error)
        if let isValidError = isValidError {
            let isValid = isValidError(error)
            if !isValid {
                print("validation failed: ", error.localizedDescription)
            }
            XCTAssertTrue(isValid, "Invalid error: \(error.localizedDescription)")
        }
    }
}

func XCTAssertThrows<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line, isValidError: ((Error) -> Bool)? = nil) {
    XCTAssertThrows(message, file: file, line: line, isValidError: isValidError, expression: expression)
}


func path(_ path: String) -> (Error) -> Bool {
    return { error in
        guard case let e as LiftError = error else { return false }
        return e.key == path
    }
}

extension Optional {
    /// Will try to unwrap the `self` and throw a `LiftError` using `description` if unsuccessful
    func assertNotNil(_ description: @autoclosure () -> String = "Expected value missing") throws -> Wrapped {
        switch self {
        case nil:
            throw LiftError(description())
        case let val?:
            return val
        }
    }
}


public let fromIso8601 = { val in try DateFormatter.iso8601.date(from: val).assertNotNil("Invalid ISO8601 date") }

public extension Date {
    var asIso8601: String {
        return DateFormatter.iso8601.string(from: self)
    }
}
