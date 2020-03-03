import Combine
import Foundation

/// A definition for a Deluge upload request.
public struct UploadRequest<Value> {
    /// The local file URL of the file to upload.
    public var fileURL: URL
    /// The MIME type of the file being uploaded.
    public var mimeType: String
    /// Transforms the server response in to a new representation.
    public var transform: ([String: Any]) -> Transform<Value>

    /// Creates an `UploadRequest` with the given parameters.
    /// - Parameters:
    ///   - fileURL: The local file URL of the file to upload.
    ///   - mimeType: The MIME type of the file being uploaded.
    ///   - transform: Transforms the server response in to a new representation.
    public init(
        fileURL: URL,
        mimeType: String,
        transform: @escaping ([String: Any]) -> Transform<Value>
    ) {
        self.fileURL = fileURL
        self.mimeType = mimeType
        self.transform = transform
    }
}

public extension UploadRequest {
    /// Creates a new request by mapping the `Value` of the request in to a new representation.
    /// - Parameter transform: Transforms the value in to a new representation.
    /// - Returns: The newly created request.
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> UploadRequest<NewValue> {
        UploadRequest<NewValue>(
            fileURL: fileURL,
            mimeType: mimeType,
            transform: {
                switch self.transform($0) {
                case let .result(result):
                    return .result(result.map(transform))
                case let .request(request):
                    return .request(request.map(transform))
                }
            }
        )
    }
}
