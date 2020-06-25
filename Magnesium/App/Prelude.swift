@_exported import Extensions

// swiftlint:disable:next identifier_name
func with<Value: AnyObject>(_ value: Value, _ f: (Value) -> Void) -> Value {
    f(value)
    return value
}

// swiftlint:disable:next identifier_name
func with<Value>(copy value: Value, _ f: (inout Value) -> Void) -> Value {
    var value = value
    f(&value)
    return value
}
