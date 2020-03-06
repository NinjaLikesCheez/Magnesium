# Preferences

A Combine powered preferences library.

## Usage

```swift
import Preferences

let preferences = UserDefaultsPreferences()
let key = PreferenceKey("my-setting", defaultValue: 1)
preferences.value(for: key) // 1
preferences.set(2, for: key)
```

## Observation

You can observe changes to `Preferences` using the `preferencesChanged` publisher or the provided convenience methods.

> ⚠️ **IMPORTANT**: The publisher will only emit values for changes made through its `Preferences`. It is recommended to use dependecy injection to share `Preferences` throught your code.

There are two methods provided to observe a specific preference key.

**`valueUpdatedPublisher(for:)`**

This publisher emits values when the preference is changed.

```swift
import Combine
import Preferences

var cancellables = Set<AnyCancellable>()

let preferences = UserDefaultsPreferences()
let key = PreferenceKey("my-setting", defaultValue: 1)
preferences.valueUpdatedPublisher(for: key).sink { print($0) }.store(in: &cancellables)
preferences.set(2, for: key)
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
preferences.set(2, for: key)
```

Output
```
1
2
```


## Installation

### Xcode 11+

* Select **File** > **Swift Packages** > **Add Package Dependency...**
* Enter the package repository URL: `shttps://github.com/jameshurst/Deluge-Swift.git`
* Confirm the version and let Xcode resolve the package

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
