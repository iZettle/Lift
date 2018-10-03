<img src="https://github.com/iZettle/Lift/blob/master/lift-logo.png?raw=true" height="140px" />

[![Build Status](https://travis-ci.org/iZettle/Lift.svg?branch=master)](https://travis-ci.org/iZettle/Lift)
[![Platforms](https://img.shields.io/badge/platform-%20iOS%20|%20macOS%20|%20tvOS%20|%20linux-gray.svg)](https://img.shields.io/badge/platform-%20iOS%20|%20macOS%20|%20tvOS%20|%20linux-gray.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager Compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

Lift is a Swift library for generating and extracting values into and out of JSON-like data structures. Lift was carefully designed to meet the following requirements:

- Use easy and intuitive syntax using subscripting.
- Be extendable for use with your custom types.
- Support of retroactive modeling/conformance.
- Do not enforce how to structure your data models.
- Be type safe and explicit about errors.
- Work with any key value structured data such as p-lists and user defaults.
- Provide detailed errors and support custom validation.
- Use value semantics for the `Jar` container.

### Example usage

Lift is simple, yet powerful. Let us see how to use it with a custom type:

```swift
struct User {
  let name: String
  let age: Int
}
```

Just conform to `JarElement` to let Lift know how to transform your type:

```swift
extension User: JarElement {
  init(jar: Jar) throws {
    name = try jar["name"]^
    age = try jar["age"]^
  }
 
  var jar: Jar {
    return ["name": name, "age": age]
  }
}
```

Then given some JSON, you can now construct a `Jar` and extract users from it using the lift operator `^`:

```swift
let json = "[{\"name\": \"Adam\", \"age\": 25}, {\"name\": \"Eve\", \"age\": 20}]"
let jar = try Jar(json: json)
var users: [User] = try jar^
```

And it is as easy to move your model values back to JSON:

```swift
users.append(User(name: "Junior", age: 2))
let newJson = try String(json: Jar(users), prettyPrinted: true)
```

Lift will even work with other JSON-like structured data such as p-lists and `UserDefaults`:

```swift
let users: [User] = try UserDefaults.standard["users"]^
```

Check the [Usage](#usage) section for more information and examples.

### Contents:

- [Requirements](#requirements)
- [Installation](#installation)
- [Note on `Codable`](#note-on-codable)
- [Usage](#usage)
	- [Introduction](#introduction)
	- [JSON Serialization](#json-serialization)
	- [Generating JSON](#generating-json)
	- [Modifying JSON](#modifiying-json)
	- [Arrays](#arrays)
	- [Missing values](#missing-values)
	- [Heterogenuos values](#heterogenuos-values)
	- [Transformation of values](#transformation-of-values)
	- [Beyond JSON](#beyond-json)
	- [Handling custom types](#handling-custom-types)
	- [Model structure](#model-structure)
	- [Handling errors](#handling-errors)
- [Field tested](#field-tested)
- [Learn more](#learn-more)
- [Collaborate](#collaborate)

## Requirements

- Xcode `9.3+`
- Swift 4.1
- Platforms:
  * iOS `9.0+`
  * macOS `10.11+`
  * tvOS `9.0+`
  * watchOS `2.0+`
  * Linux


## Installation

#### [Carthage](https://github.com/Carthage/Carthage)

```shell
github "iZettle/Lift" >= 2.0
```

#### [Cocoa Pods](https://github.com/CocoaPods/CocoaPods)

```ruby
platform :ios, '9.0'
use_frameworks!

target 'Your App Target' do
  pod 'Lift', '~> 2.0'
end
```

#### [Swift Package Manager](https://github.com/apple/swift-package-manager)

```swift
import PackageDescription

let package = Package(
  name: "Your Package Name",
  dependencies: [
      .Package(url: "https://github.com/iZettle/Lift.git",
               majorVersion: 2)
  ]
)
```

## Note on `Codable`

Swift 4 introduced `Codable` with the "promise" to have solved working with JSON once and for all. And yes, many of the examples shown are just close to magic. But when your models start to diverge from the simple ones to ones mapping between model and JSON, the magic seems to go away. Now you are back to implementing everything yourself and this using a quite verbose API. The current version of Swift also lacks APIs for building and parsing JSON on the fly (not going through model objects) which is common when e.g. building and parsing network requests. Hence, we believe the demand for third party JSON libraries will still be there for some time to come.

## Usage

### Introduction

Let us start out with a simple example of how to extract data from some key value structured data such as JSON:

```swift
let jar: Jar = ["name": "Lift", "version": 1.0]
let name: String = try jar["name"]^
let version: Double = try jar["version"]^
```

`Jar` is Lift's container of heterogenous values. In this example it holds a dictionary. The operator `^` (called the lift operator) is used to extract values out of the jar container. Because the jar typically holds values that are not known at compile time, extracting them might fail. This might happen if the value is missing, if the value is not of the expected type, or if some other validation is failing. This is why you will always see a `try` in the presence of the lift operator `^`.

As mentioned, JSON does not always come in the form of a dictionary (key-values), but could also be simple primitive types or arrays of other JSON objects:

```swift
let i: Int = try Jar(1)^
let b: Bool = try Jar(true)^
let a: [Int] = try Jar([1, 2, 3])^
let jar: Jar = ["value": "lift"]
let s: String = try jar["value"]^
```

The `^` operator is overloaded to allow conforming types to either be extracted as the type itself or as an optional version of it. You can also extract an array or optional array of conforming types:

```swift
let i: Int = try jar^
let i: Int? = try jar^
let i: [Int] = try jar^
let i: [Int]? = try jar^
```

`Jar` implements subscripting for keys and indices and also allows them to be nested:

```swift
let date: Date = try jar["payments"][3]["date"]^
jar["payments"][2]["date"] = Date()
```


### JSON serialization

Lift adds convenience initializers to construct a `Jar` from JSON and back:

```swift
let json = "{ \"val\": 3, \"vals\": [ 1, 2 ] }"
let jar = try Jar(json: json)
let jsonString = try String(json: jar, prettyPrinted: true)
let jsonData = try Data(json: jar, prettyPrinted: false)
```

You could also handle the serialization yourself and just pass an `Any` value:

```swift
let json: Any = ...
let jar = try Jar(checked: json) // Will validate when constructed - slower
let jar = Jar(unchecked: json) // Will lazily validate at access - faster

let any: Any = try jar.asAny()
```

### Generating JSON

To help creating JSON, `Jar` implements several _expressible by literal_ protocols so you can write code like:

```swift
func send(_ jar: Jar) { ... }

send(true)
send(1)
send(3.14)
send("Hello")
send(["val": 5])
send([1, 2, 3])
```

When `Jar` can't be inferred by the complier, you can explicitly specify the type:

```swift
let jar: Jar = ["val": 5]
let jar: Jar = [1, 2, 3]
```

You can also build nested hierarchies:

```swift
let jar: Jar = [5, ["val": [1, 2]]]
```

And of course you can also build JSON from your custom types:

```swift
let jar: Jar = ["payment": payment, "date": date]
```

### Modifying JSON

Because `Jar` is a value type with value semantics, you can modify your `Jar` value when declared as `var`.

```swift
var jar = Jar()
jar["payment"] = payment
jar["date"] = Date()
```

```swift
var jar = Jar()
jar.append(payment)
jar.append(Date())
```

And if you need to modify your JSON before passing it on just make a copy:

```swift
func receive(jar: Jar) {
  var jar = jar
  jar["timeReceived"] = Date()
  // ...
}
```

A `Jar` is never bound to a specific type or value, hence it is always ok to change it:

```swift
var jar: Jar = true // jar holds a boolean
jar = [1, 2] // holds an array
jar["val"] = 1 // holds a dictionary
jar = 4711 // holds an integer
jar = ["val2": 2] // holds a dictionary
jar = "Hello" // holds a string
```


### Arrays

Lift supports working with arrays of primitive types:

```swift
var jar: Jar = [1, 2, 3]

jar[1] = 4
jar.append(5)

let val: Int = try jar[2]^
```

As well as arrays of your custom types:

```swift
var jar: Jar = [Payment(...), Payment(...), ...]

let payments: [Payment] = try jar^
jar[2] = Payment(...)
```


### Missing values and JSON null

Sometimes the existence of a value is a requirement, sometimes it is optional.

```swift
let i: Int = try jar["val"]^ // Will throw if val is missing or not an Int
let i: Int? = try jar["val"]^ // Will return nil if val is missing or null, else throw if not an Int
let i: Int = try jar["val"]^ ?? 4711 // Will throw if val is present and is not an Int
```

For your convenience Lift treats a value set to JSON null the same as a missing value. But if you need to check for the presence of the actual null value itself you can write:

```swift
if let _: Null = try? jar["val"]^ {
  //...
}
```

When building your JSON it is quite common that some values are optional:

```swift
let optional: Int? = nil
var jar: Jar = ["val": 1]
jar["optional"] = optional // -> {"val": 1}
```

It is also possible to add your optional inline:

```swift
var jar: Jar = ["val": 1, "optional": optional] // -> {"val": 1}
```

If you actually want a JSON null value you can use the constant `null`:

```swift
var jar: Jar = ["val": 1, "optional": optional ?? null] // -> {"val": 1, "optional": null}
```

### Heterogenous values

Sometimes parts of your JSON could hold the union of different kinds of valid types. Then you could test between the different variations you support:

```swift
let any: Any? = NSJSONSerialization...
let jar = try Jar(any) // any could be a dictionary, array or a primitive type

if let int: Int = try? jar^ {
  // ...
} else if let ints: [Int] = try? jar^ {
  // ...
} else if let int: Int = try? jar["value"]^ {
  // ...
}
```

JSON also supports arrays of mixed types:

```swift
let jar = try Jar(any) // [ 1, [1, 2], { "val" : 3 } ] -- [Int, Array, Dictionary]

let int: Int = try jar[0]^
let array: [Int] = try jar[1]^
let dict: Jar = try jar[2]^
```

### Transformation of values

You sometimes need to transform the values extracted from a `Jar` before using them. This might happen when you are working with types that cannot conform to `JarRepresentable`, such as when using tuples:

```swift
typealias User = (name: String, age: Int)
let users: [User] = try (jar^ as [Jar]).map { jar in 
  try (jar["name"]^, jar["age"]^) 
}
```

Or when your type does not conform to `JarRepresentable`, as it might need some additional initialization data:

```swift
let account: Account = ...

let payments: [Payment] = try (jar["payments"]^ as Array).map {
  Payment(jar: $0, account: account)
}
```

Even though you can manually transform values to add additional initialization data, it is often more convenient to add this data to the jar's context instead. Jar contexts will be described further down.

### Beyond JSON

Setting and getting values of unknown types is not unique to JSON. Many Cocoa APIs use dictionaries and many of them are based on similar principles as JSON, such as p-lists. Lift provides protocols for extending those types to grant them  access the power of Lift. E.g. Lift already extends UserDefaults:

```swift
// extension UserDefaults: MutatingValueForKey { }

let userDefaults = UserDefaults.standard

let date: Date? = try userDefaults["lastLaunched"]^
userDefaults["lastLaunched"] = Date()

let payments: [Payments] = try userDefaults["payments"]^ ?? []
```

### JarConvertible & JarRepresentable

Out of the box, the Lift library supports JSON dictionaries, arrays and its primitive types: string, number, bool and null. But it is easy to extend your own types to work with the Lift library as well.

To be able extract values out of a `Jar` using the lift operator `^`, you conform your type to the `JarConvertible` protocol:

```swift
protocol JarConvertible {
  init(jar: Jar) throws
}
```

And to be able to convert your type to a `Jar`, you conform your type to `JarRepresentable`:

```swift
protocol JarRepresentable {
  var jar: Jar { get }
}
```

It is common to implement both these protocols hence the convenience `JarElement` type alias:

```swift
typealias JarElement = JarConvertible & JarRepresentable
```

The Lift library includes extensions for the most common primitive types such as `Int`, `Bool`, `String`, etc., by conforming them to `JarElement`.


### Handling custom types

Your custom types are typically either simple types such as:

```swift
struct Money {
  let fractionized: Int
}

extension Money: JarElement {
  init(jar: Jar) throws {
    fractionized = try jar^
  }

  var jar: Jar { return Jar(fractionized) }
}

let jar: Jar = ["amount": Money(fractionized: 2000)]
let amount: Money = try jar["amount"]^
```

Or perhaps more common, more complex and record like types such as:

```swift
struct Payment {
  let amount: Money
  let date: Date
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

let jar: Jar = ["payment": Payment(...)]
let payment: Payment = try jar["payment"]^
```

To make it easier to conform your custom enums with raw values, Lift comes with some default implementations. All you have to do is to conform the enum to `JarElement` to be able to use it with `Jar`s:

```swift
enum MyEnum: String, JarElement {
  case one, two, three
}

let jar: Jar = ["enum": MyEnum.two]
let str: String = try jar["enum"]^ // -> "two"
let myEnum: MyEnum = try jar["enum"]^ // -> .two
```

`JarConvertible` requires you to implement a required init. This can be problematic if you work with non-final classes where you cannot update the source itself, such as when the class originates from Objective-C or another external source. In those cases you have to use the `Liftable` protocol instead:

```swift
extension MyClass: Liftable {
  static func lift(from jar: Jar) throws -> MyClass {
    // Implementation
  }
}
```

### Model structure

The Lift library does not enforce the structure of you custom types and also allows retroactive modeling. It is up to you how you decide to map between your types and JSON. For example you might have enums with associative values (in this example a recursive one):

```swift
// [ { "type": "Product", "uuid": ”3b0bb980-2c…” },
//   { "type": "Folder", "name": "Coffee", "items": [
//        { "type": "Product", "uuid": ”3e493140-2c…” },
//        { "type": "Product", ”uuid": ”3e623780-2c…” }] },
//   ... ]

indirect enum FlowLayout {
  case product(uuid: UUID)
  case folder(name: String, items: [FlowLayout])
}
```

Because the JSON format has a weaker type-system than Swift, stricter validation becomes more important:

```swift
extension FlowLayout: JarConvertible  {
  init(jar: Jar) throws {
    switch try jar["type"]^ as String {
    case "Product":
      self = try .product(uuid: jar["uuid"]^)
    case "Folder":
      self = try .folder(name: jar["name"]^, items: jar["items"]^)
    case let type:
      throw jar.assertionFailure("Unknown layout type: \(type)")
    }
  }
}
```

Even for these more complex types, generation of JSON is still quite straightforward:

```swift
extension FlowLayout: JarRepresentable {
  var jar: Jar {
      switch self {
      case let .product(uuid):
        return ["type": "Product", "uuid": uuid]
      case let .folder(name, items):
        return ["type": "Folder", "name": name, "items": items]
    }
  }
}
```

### Handling errors

Because JSON is typically nested, it is useful to extend errors with some positioning and context. Lift tries to keep track of the closest context and "key-path" into your data and will expose those in `LiftError`s:

```swift
struct LiftError: Error {
  let description: String
  let key: String
  let context: String
}
```

Because the context and key-path are really valuable during debugging, it is important to not lose those when throwing validation errors. Hence, Lift has added special assert helper methods to `Jar` that you are encouraged to use:

```swift
init(jar: Jar) throws {
  // ...
  try jar.assert(i > 0, "Must greater than zero")

  guard validate(...) else {
    throw jar.assertionFailure("Not a business nor a person")
  }
  
  url = try jar.assertNotNil(URL(string: jar^), "Invalid URL")
  // ...
}
```

### Jar context

Sometimes your type's initializer needs access to more data than what is included in the JSON itself. E.g. perhaps your `Money` type needs a currency as well, but your JSON does not provide that or provides it far away from the actual amount value itself. This is where you can pass the currency in the jar's context instead:

```swift
struct Money {
  let fractionized: Int
  let currency: Currency
}

extension Money: JarElement {
  init(jar: Jar) throws {
    fractionized = try jar^
    currency = try jar.context.get() // will extract the currency
  }

  var jar: Jar { return Jar(fractionized) }
}

let amount: Money = try jar.union(context: currency)["amount"]^
```

The jar's context is also useful for customizing the encoding and decoding of your types. E.g. `Date` will by default use the ISO8601 date format, but by providing another `DateFormatter` in the jar's context you could customize the date format:

```swift
extension Date: JarConvertible, JarRepresentableWithContext {
  init(jar: Jar) throws {
    let formatter: DateFormatter = jar.context.get() ?? .iso8601
    self = try jar.assertNotNil(formatter.date(from: jar^), "Date failed to convert using formatter with dateFormat: \(formatter.dateFormat)")
  }

  func asJar(using context: Jar.Context) -> Jar {
    let formatter: DateFormatter = context.get() ?? .iso8601
    return Jar(formatter.string(from: self))
  }
}
```

As `JarRepresentable` does not provide any context, you will instead conform to `JarRepresentableWithContext` that passes the context in `asJar`:

```swift
protocol JarRepresentableWithContext: JarRepresentable {
  func asJar(using context: Jar.Context) -> Jar
}
```

The context could either be set externally or as part of some other type's encoding/decoding such as:

```swift
struct Payment {
  let amount: Money
  let date: Date
}

extension Payment: JarElement {
  init(jar: Jar) throws {
    let jar = jar.union(context: DateFormatter.custom)
    amount = try jar["amount"]^ // a currency must be provided in the jar's context
    date = try jar["date"]^ // date will format using DateFormatter.custom
  }

  var jar: Jar {
    let jar: Jar = ["amount": amount, "date": date]
    return jar.union(context: DateFormatter.custom)
  }
}

let payment: Payment = try jar.union(context: currency)["payment"]^
```

## Field tested

Lift was developed, evolved and field-tested over the course of several years, and is pervasively used in [iZettle](https://izettle.com)'s highly acclaimed point of sales app for communicating with iZettle's comprehensive set of backend services.

## Collaborate

You can collaborate with us on our Slack workspace. Ask questions, share ideas or may be just participate in ongoing discussions. To get an invitation, write to us at [ios-oss@izettle.com](mailto:ios-oss@izettle.com)

## Learn more

To learn more about how Lift's APIs turned the way they did, we recommend reading the article:

- [API Design - Deriving Lift](https://medium.com/izettle-engineering/deriving-lift-d83f8b6d0b38)
