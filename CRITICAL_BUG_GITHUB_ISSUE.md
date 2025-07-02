# CRITICAL BUG - GitHub Issue

**Repository**: https://github.com/NinjaLikesCheez/Magnesium

## Issue Title
Critical Bug: App crashes with fatalError when keychain data is missing

## Issue Body

### Bug Description

The app crashes with `fatalError("Failed to fetch keychain data for server: \(server)")` when keychain data is nil or missing. This can happen in legitimate scenarios such as:

- First app launch before any servers are configured
- Keychain corruption or reset
- App reinstallation without keychain restoration
- System keychain access issues

### Location
`Sources/Magnesium/Models/Session/Session.swift:57`

### Steps to Reproduce
1. Install the app fresh (or clear keychain data)
2. Add a Deluge server but don't complete the keychain setup properly
3. Try to use the server
4. App crashes with fatalError

### Expected Behavior
The app should handle missing keychain data gracefully with proper error handling and user feedback.

### Suggested Fix
Replace the fatalError with proper error handling:

```swift
guard let keychainData = server.keychainData else {
    // Handle missing keychain data gracefully
    throw SessionError.missingKeychainData(server: server)
}
```

### Impact
- **Severity**: Critical (app crash)
- **Frequency**: Can occur during normal usage  
- **User Experience**: Catastrophic - app becomes unusable

### Additional Context
This is part of a larger pattern in the codebase where fatalError is used instead of proper error handling. Other related crashes exist at:
- Session.swift:66 (decoding errors)
- Session.swift:80 (QBittorrent not implemented)

This bug was identified during a comprehensive code review and should be fixed immediately to prevent app crashes in production.

### Labels
- bug
- critical

---

**To create this issue**: Go to https://github.com/NinjaLikesCheez/Magnesium/issues/new and copy the content above.