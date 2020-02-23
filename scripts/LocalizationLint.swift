#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

// MARK: - Config

/// The configuration to use when running the script.
struct Config {
    /// The directory containing the source code.
    let sources: String
    /// The directory containing the lproj directories.
    let localizations: String
    /// The localization patterns to match.
    let patterns = ["NSLocalizedString\\(\\s*\"([\\w\\.]+)\""]
    /// Any keys that should be ignored for linting.
    let ignoredKeys = [String]()
    /// The master language for localization.
    let masterLanguage = "en"
}

let config = Config(
    sources: "Magnesium",
    localizations: "Magnesium/Resources/Localization"
)

// MARK: - Script

/// Localization linting errors.
enum Error: Swift.Error {
    /// The localizations path from `Config` was invalid.
    case invalidLocalizationsURL(URL)
}

extension Error: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidLocalizationsURL(url):
            return "Invalid localizations path: \(url.path)"
        }
    }
}

/// A representation of a localization.
struct Localization {
    /// A parsed localization value from either `Localizable.strings` or `Localizable.stringsdict`.
    enum LocalizedValue {
        /// A localized value from a strings file.
        case string(url: URL, value: String, lineNumber: Int)
        /// A localized value from a stringsdict file.
        case dict(url: URL)

        /// The file URL that contained the localized value.
        var url: URL {
            switch self {
            case let .string(url, _, _):
                return url
            case let .dict(url):
                return url
            }
        }

        /// The line number where the localized value was found.
        var lineNumber: Int {
            switch self {
            case let .string(_, _, lineNumber):
                return lineNumber
            case .dict:
                return 0
            }
        }
    }

    /// The lproj directory for the localization.
    let directory: URL
    /// A map of localization keys to localized values.
    private(set) var keys = [String: LocalizedValue]()
    /// The list of errors encountered while parsing the localizations.
    private(set) var errors = [String]()

    /// Creates a new `Localization` with the given lang and baseURL. The localization will be immediately parsed and
    /// populate the `keys` and `errors` properties based on the results.
    /// - Parameters:
    ///   - lang: The language code of the localization.
    ///   - baseURL: The base localizations directory.
    /// - Throws: Any error that occurred during localization parsing.
    init(lang: String, baseURL: URL) throws {
        directory = baseURL.appendingPathComponent("\(lang).lproj", isDirectory: true)
        try processLocalizableStrings()
        try processLocalizableStringsDict()
    }

    private mutating func processLocalizableStrings() throws {
        let url = directory.appendingPathComponent("Localizable.strings")
        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.components(separatedBy: .newlines)
        let regex = try NSRegularExpression(pattern: "\"(.*)\" = \"(.+)\";", options: [])

        for (lineNumber, line) in lines.enumerated() {
            let range = NSRange(location: 0, length: line.count)
            guard let match = regex.firstMatch(in: line, options: [], range: range) else { continue }
            let key = (line as NSString).substring(with: match.range(at: 1))
            let value = (line as NSString).substring(with: match.range(at: 2))
            guard keys[key] == nil else {
                errors.append("\(url.path):\(lineNumber + 1): warning: Duplicate key \"\(key)\"")
                continue
            }
            keys[key] = .string(url: url, value: value, lineNumber: lineNumber + 1)
        }
    }

    private mutating func processLocalizableStringsDict() throws {
        let url = directory.appendingPathComponent("Localizable.stringsdict")
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let data = try Data(contentsOf: url)
        let anyContents = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let contents = anyContents as? [String: Any] else { return }
        for key in contents.keys {
            guard keys[key] == nil else {
                errors.append("\(url.path):0: warning: Duplicate key \"\(key)\"")
                continue
            }
            keys[key] = .dict(url: url)
        }
    }
}

/// Returns the list of supported languages based on the contents of the provided localizations directory.
/// - Parameter localizationsURL: The base localizations directory.
/// - Throws: If the localization was unable to be parsed.
/// - Returns: The supported languages.
func getSupportedLanguages(in localizationsURL: URL) throws -> [String] {
    guard FileManager.default.fileExists(atPath: localizationsURL.path) else {
        throw Error.invalidLocalizationsURL(localizationsURL)
    }

    return try FileManager.default.contentsOfDirectory(at: localizationsURL, includingPropertiesForKeys: nil)
        .compactMap { url in
            guard url.pathExtension == "lproj" else { return nil }
            return url.deletingPathExtension().lastPathComponent
        }
}

/// Performs linting.
/// - Throws: Any error that occurred during linting.
func main() throws {
    /// A localized key usage found in the source files.
    struct UsedKey {
        /// The file URL where the key was found.
        let url: URL
        /// The localized key that was found.
        let key: String
        /// The line number where the localized key was found.
        let lineNumber: Int
    }

    let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    let localizationsURL = pwd.appendingPathComponent(config.localizations)
    let sourcesURL = pwd.appendingPathComponent(config.sources)
    let supportedLanguages = try getSupportedLanguages(in: localizationsURL)
    let masterLocalization = try Localization(lang: config.masterLanguage, baseURL: localizationsURL)
    let localizations = try supportedLanguages
        .filter { $0 != config.masterLanguage }
        .map { try Localization(lang: $0, baseURL: localizationsURL) }

    // Print out the errors generated by Localization parsing
    for localization in [masterLocalization] + localizations {
        for error in localization.errors {
            print(error)
        }
    }

    /// Gather used keys from source files using regexes defined in `Config.patterns`
    var usedKeys = [UsedKey]()
    let regexes = try config.patterns.map { try NSRegularExpression(pattern: $0, options: []) }
    let enumerator = FileManager.default.enumerator(at: sourcesURL, includingPropertiesForKeys: nil)!
    for case let url as URL in enumerator {
        guard url.pathExtension == "swift" else { continue }
        let contents = try String(contentsOf: url, encoding: .utf8)
        for regex in regexes {
            let range = NSRange(location: 0, length: contents.count)
            regex.enumerateMatches(in: contents, options: [], range: range) { result, _, _ in
                guard let result = result else { return }
                let range = result.range(at: result.numberOfRanges - 1)
                let key = (contents as NSString).substring(with: range)
                // determine the line number based on the number of newlines before the match location
                let lineNumber = (contents[..<contents.index(contents.startIndex, offsetBy: range.location)])
                    .components(separatedBy: .newlines)
                    .count
                usedKeys.append(UsedKey(url: url, key: key, lineNumber: lineNumber + 1))
            }
        }
    }

    let masterKeys = Set(masterLocalization.keys.keys)

    // Print out unused localization keys
    let unusedKeys = masterKeys.subtracting(Set(usedKeys.map { $0.key })).subtracting(Set(config.ignoredKeys))
    for key in unusedKeys {
        let value = masterLocalization.keys[key]!
        print("\(value.url.path):\(value.lineNumber): warning: Unused key \"\(key)\"")
    }

    // Print out keys with missing localizations
    let missingKeys = usedKeys.filter { !masterKeys.contains($0.key) }
    for key in missingKeys {
        print("\(key.url.path):\(key.lineNumber): warning: Localized key \"\(key.key)\" is missing translation")
    }
}

do {
    try main()
} catch {
    print(error.localizedDescription)
    exit(-1)
}
