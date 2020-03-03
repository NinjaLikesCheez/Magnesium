# Deluge

A Combine powered Deluge API client.

## Usage

```swift
import Combine
import Deluge

var cancellables = Set<AnyCancellable>()

let client = Client(baseURL: URL(string: "https://my.torrent.server")!, password: "secret!")
client.request(.authenticate)
    .sink(receiveCompletion: { _ in }, receiveValue: { _ in
        print("Authenticated!")
    })
    .store(in: &cancellables)
```

## Requests

A `Request` describes a request type and parameters.

There are many types of requests already built in. You can see the built-in request types referring to the [documentation](Documentation/Requests.md) or by typing `client.request(.` and observing the autocomplete results.

There are two types of `Requests`:
- `.rpc(RPCRequest)`
- `.upload(UploadRequest)`

**RPCRequest**

An `RPCRequest` makes an HTTP POST request to `/json`. You can use this type of request to interact with the Deluge JSON-RPC API.

**UploadRequest**

An `UploadRequest` makes an HTTP POST request to `/upload` with a multipart form. You can use this type of request to upload a torrent to the Deluge server.

## Transforms

Requests accept a closure that returns a `Transformed` value.

**.result**

A `Transformed.result` value causes the request to complete with the contained `Result`.

```swift
static func resume(hashes: [String]) -> Request<Void> {
    return .rpc(.init(method: "core.resume_torrent", params: [hashes]) { response -> Transformed<Void> in
        return .result(.success(()))
    })
}
```
> NOTE: This request is already included.

**.request**

A `Transformed.request` value causes a new `Request` to be sent. You can use this result to perform multi-request operations.

```swift
static func add(fileURL: URL) -> Request<Void> {
    return .upload(.init(
        fileURL: fileURL,
        mimeType: "application/x-bittorrent",
        transform: { response -> Transformed<Void> in
            guard let path = (response["files"] as? [String])?.first else {
                return .result(.failure(.unexpectedResponse))
            }

            return .request(.rpc(.init(
                method: "web.add_torrents",
                params: [[["path": path, "options": [String: Any]()]]]
            )))
        }
    ))
}
```
> NOTE: This request is already included.
