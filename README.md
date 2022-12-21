
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
let loader = ImageLoader(cache: Cache(type: .cacheInfo(name: "CombineLoader"), config: .init(clearCacheType: .both)),
                         config: .init(showLog: true, keepOnlyLatestHandler: false),
                         executeQueue: taskQueue, receiveQueue: .main)
```

```swift
imageLoader.loadValue(from: url, key: url.absoluteString) { result, resultUrl in
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
let cacheImage = try ImageLoader.shared.cacheValue(for: url)
```

Use also can create your own Cache Loader based on **CacheLoader** protocol or **BaseLoader** class as follows:
```swift
class SampleLoader: BaseLoader<Sample> {
    static let shared = SampleLoader(cache: Cache(type: .cacheInfo(name: "SampleLoader.shared"), config: .init(clearCacheType: .both)),
                                     config: .init(showLog: false, keepOnlyLatestHandler: true),
                                     executeQueue: OperationQueue(),
                                     receiveQueue: .main)
    
    override init(cache: any Cacheable<Key, Sample>,
                  config: CacheLoaderConfig,
                  executeQueue: OperationQueue,
                  receiveQueue: OperationQueue = .main) {
        super.init(cache: cache, config: config, executeQueue: executeQueue, receiveQueue: receiveQueue)
    }
    
    override func value(from data: Data) throws -> Sample? {
        return try Sample.fromData(data)
    }
}

// Sample model for that json: https://tools.learningcontainer.com/sample-json.json
struct Sample: Codable {
    let firstName: String
    let lastName: String
    let gender: String
    let age: Int
}

extension Sample: DataTransformable {
    func toData() throws -> Data {
        let data = try JSONEncoder().encode(self)
        return data
    }
    
    static func fromData(_ data: Data) throws -> Sample? {
        return try? JSONDecoder().decode(Sample.self, from: data)
    }
}
```
