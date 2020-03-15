# Preferences

A Combine powered preferences library.

## Usage

```swift
import Preferences

let preferences = UserDefaultsPreferences()
let key = PreferenceKey("my-setting", defaultValue: 1)

// Verbose syntax. Methods can throw errors.
preferences.value(for: key) // 1
try preferences.set(2, for: key)

// Subscript syntax. Errors will be discarded.
preferences[key] // 1
preferences[key] = 2
```

`Preferences` supports using any values that conform to `Codable`.

The `value(for:)` and `set(_:for:)` methods will `throw` an error if the value was unable to be encoded or decoded. To access preferences without worrying about errors you can use the subscript syntax.

## Preferences Protocol

The `Preferences` protocol provides a unified interface for different preference storage implementations.

There are two types of `Preferences`:
* `UserDefaultsPreferences`: This implementation persists values in `UserDefaults`.
* `InMemoryPreferences`: This implementation stores values in memory.

## Observation

You can observe changes to `Preferences` using the `preferencesChanged` publisher or the provided convenience methods.

> ⚠️ **IMPORTANT**: The publisher will only emit values for changes made through its associated `Preferences` instance. It is recommended to use dependency injection to share `Preferences` throughout your code.

There are two methods provided to observe specific preference keys.

**`valueUpdatedPublisher(for:)`**

This publisher emits values when the preference is changed.

```swift
import Combine
import Preferences

var cancellables = Set<AnyCancellable>()

let preferences = UserDefaultsPreferences()
let key = PreferenceKey("my-setting", defaultValue: 1)
preferences.valueUpdatedPublisher(for: key).sink { print($0) }.store(in: &cancellables)
try preferences.set(2, for: key)
```

Output
```
2
```

**`valuePublisher(for:)`**

This publisher emits the current preference value and new values when the preference is changed.

```swift
import Combine
import Preferences

var cancellables = Set<AnyCancellable>()

let preferences = UserDefaultsPreferences()
let key = PreferenceKey("my-setting", defaultValue: 1)
preferences.valuePublisher(for: key).sink { print($0) }.store(in: &cancellables)
try preferences.set(2, for: key)
```

Output
```
1
2
```


## Installation

### Xcode 11+

* Select **File** > **Swift Packages** > **Add Package Dependency...**
* Enter the package repository URL: `shttps://github.com/jameshurst/Preferences-Swift.git`
* Confirm the version and let Xcode resolve the package

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
