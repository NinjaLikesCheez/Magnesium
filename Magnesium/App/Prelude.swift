@_exported import Extensions

// swiftlint:disable:next identifier_name
func with<Value>(_ value: Value, _ f: (Value) -> Void) -> Value {
    f(value)
    return value
}
