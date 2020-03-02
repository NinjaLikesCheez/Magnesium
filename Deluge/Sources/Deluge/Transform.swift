/// A transform that results in `Value`.
public enum Transform<Value> {
    /// A transform resulting in a `Result`.
    case result(Result<Value, Client.Error>)
    /// A transform resulting in a new request.
    case request(Request<Value>)
}
