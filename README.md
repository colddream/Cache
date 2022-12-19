
# Introduction

**Cache** is an open-source support for caching any data (Ex: Image, etc...).


# Installation

Cache is packaged as a dynamic framework that you can import into your Xcode project. You can install this manually, or by using Swift Package Manager.

**Note:** Cache requires Xcode 13+ to build, and runs on iOS 11+.

To install using Swift Package Manage, add this to the `dependencies:` section in your Package.swift file:

```swift
.package(url: "https://github.com/colddream/Cache", .upToNextMinor(from: "1.0.0")),
```


# Usage

Using **Cache** as follows:
```swift
let cache = Cache<String, Int>(config: .init(countLimit: 5, totalCostLimit: 5 * 1024 * 1024))

// Set
cache.set(1, for: "Key1")
cache["Key1"] = 1

// Get
let value1 = cache.value(for: "Key1")
let value2 = cache["Key6"]
```

Using of **ImageLoader** as follows:

```swift
let executeQueue = OperationQueue()
executeQueue.maxConcurrentOperationCount = 6
let imageLoader = ImageLoader(cache: Cache<URL, UIImage>(config: .init(countLimit: 50, totalCostLimit: 50 * 1024 * 1024)),
                            executeQueue: executeQueue,
                            receiveQueue: .main)
```

```swift
imageLoader.loadValue(from: url, keepOnlyLatestHandler: true, isLog: true) { result in
    print("Finished Load for: \(urlString)")
    switch result {
    case .success(let image):
        print("\(image)")
    case .failure(let error):
        print("\(error.localizedDescription)")
    }
}
```

You can get cache image dirrectly if exist as follows:

```swift
let cacheImage = ImageLoader.shared.cacheValue(for: url)
```

Use also can create your own Cache Loader based on **CacheLoader** protocol or **BaseLoader** class as follows:
```swift
class SampleLoader: BaseLoader<Sample> {
    static let shared = SampleLoader(cache: Cache<URL, Sample>(config: .init(countLimit: 100, totalCostLimit: 50 * 1024 * 1024)),
                                     executeQueue: OperationQueue(),
                                     receiveQueue: .main)
    
    override func value(from data: Data) -> Sample? {
        return try? JSONDecoder().decode(Sample.self, from: data)
    }
    
    override init(cache: any Cacheable<URL, Sample>, executeQueue: OperationQueue, receiveQueue: OperationQueue = .main) {
        super.init(cache: cache, executeQueue: executeQueue, receiveQueue: receiveQueue)
    }
}

// Sample model for that json: https://tools.learningcontainer.com/sample-json.json
struct Sample: Codable {
    let firstName: String
    let lastName: String
    let gender: String
    let age: Int
}
```
