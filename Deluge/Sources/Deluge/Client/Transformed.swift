/// A transformed result that eventually returns `Value`.
public enum Transformed<Value> {
    //// A `Transformed.result` value causes the request to complete with the contained `Result`.
    case result(Result<Value, Client.Error>)
    /// A `Transformed.request` value causes a new `Request` to be sent. You can use this result to perform
    /// multi-request operations.
    case request(Request<Value>)
}
