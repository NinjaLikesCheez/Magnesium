/// A Deluge request.
public enum Request<Value> {
    /// An RPC request.
    case rpc(RPCRequest<Value>)
    /// An upload request.
    case upload(UploadRequest<Value>)
}

public extension Request {
    /// Creates a new request by mapping the `Value` of this request in to a new representation.
    /// - Parameter transform: Transforms the value in to a new representation.
    /// - Returns: The newly created request.
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Request<NewValue> {
        switch self {
        case let .rpc(request):
            return .rpc(request.map(transform))
        case let .upload(request):
            return .upload(request.map(transform))
        }
    }
}
