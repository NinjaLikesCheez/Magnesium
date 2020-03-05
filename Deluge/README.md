# Deluge

A Combine powered Deluge JSON-RPC API client.

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

A `Request` describes an RPC method, parameters, and a function to transform the API response in to a new representation.

There are many requests already built-in. You can view the [documentation](Documentation/Requests.md) or browse through the autocomplete menu when typing `client.request(.`.

```swift
let addMagnetURL = Request(
    method: "core.add_torrent_magnet",
    params: [magnetURL, [String: Any]()],
    transform: { response in
        guard let hash = response["result"] as? String else { return .failure(.unexpectedResponse) }
        return .success(hash)
    }
)
```
