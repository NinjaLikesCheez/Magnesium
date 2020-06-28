import Foundation

struct FileSystem {
    var isReadable: (URL) -> Bool
    var startAccessingSecurityScopedResource: (URL) -> Bool
    var stopAccessingSecurityScopedResource: (URL) -> Void
}

extension FileSystem {
    static let live = FileSystem(
        isReadable: { FileManager.default.isReadableFile(atPath: $0.path) },
        startAccessingSecurityScopedResource: { $0.startAccessingSecurityScopedResource() },
        stopAccessingSecurityScopedResource: { $0.stopAccessingSecurityScopedResource() }
    )
}
