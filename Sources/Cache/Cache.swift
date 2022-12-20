//
//  Cache.swift
//  Cache
//
//  Created by Do Thang on 11/12/2022.
//

import Foundation

/// Memory Cache
public class Cache<Value: DataTransformable> {
    // MARK: - Predefines
    
    public typealias Key = String
    /// Closure that defines the disk cache path from a given path and cacheName.
    public typealias DiskCachePathClosure = (URL, String) -> URL
    
    // MARK: - Storages
    private let memoryStorage: MemoryStorage<Key, Value>
    private let diskStorage: DiskStorage<Value>
    private let ioQueue: DispatchQueue
    
    // MARK: Initializers

    /// Creates an `ImageCache` from a customized `MemoryStorage` and `DiskStorage`.
    ///
    /// - Parameters:
    ///   - memoryStorage: The `MemoryStorage.Backend` object to use in the image cache.
    ///   - diskStorage: The `DiskStorage.Backend` object to use in the image cache.
    public init(memoryStorage: MemoryStorage<Key, Value>,
                diskStorage: DiskStorage<Value>) {
        self.memoryStorage = memoryStorage
        self.diskStorage = diskStorage
        
        let ioQueueName = "com.ipro.Cache.ioQueue.\(UUID().uuidString)"
        self.ioQueue = DispatchQueue(label: ioQueueName, attributes: .concurrent)
    }
    
    /// Creates an `ImageCache` with a given `name`, cache directory `path`
    /// and a closure to modify the cache directory.
    ///
    /// - Parameters:
    ///   - name: The name of cache object. It is used to setup disk cache directories and IO queue.
    ///           You should not use the same `name` for different caches, otherwise, the disk storage would
    ///           be conflicting to each other.
    ///   - cacheDirectoryURL: Location of cache directory URL on disk. It will be internally pass to the
    ///                        initializer of `DiskStorage` as the disk cache directory. If `nil`, the cache
    ///                        directory under user domain mask will be used.
    /// - Throws: An error that happens during image cache creating, such as unable to create a directory at the given
    ///           path.
    public convenience init(name: String,
                            cacheDirectoryURL: URL? = nil) {
        if name.isEmpty {
            fatalError("[Cache] You should specify a name for the cache. A cache with empty name is not permitted.")
        }

        // Create default memory storage
        let memoryStorage = Self.createDefaultMemoryStorage()

        // Create default disk storage
        
        do {
            let diskStorage = try Self.createDefaultDiskStorage(name: name, cacheDirectoryURL: cacheDirectoryURL)
            self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
        } catch {
            fatalError("[Cache] \(error.localizedDescription)")
        }
    }
}

// MARK: - Cacheable

extension Cache: Cacheable {
    public func set(_ value: Value, for key: Key) throws {
        memoryStorage.set(value, for: key)
        
        ioQueue.async { [weak self] in
            try? self?.diskStorage.set(value, for: key)
        }
    }
    
    public func value(for key: Key) throws -> Value? {
        if let value = memoryStorage.value(for: key) {
            return value
        }
        
        // Get value from disk
        var value: Value?
        ioQueue.sync {
            value = try? diskStorage.value(for: key)
        }
        
        // If exist value from disk => store to memory cache to use later
        if value != nil {
            memoryStorage.set(value!, for: key)
        }
        
        return value
    }
    
    public func removeValue(for key: Key) throws {
        memoryStorage.removeValue(for: key)
        ioQueue.async { [weak self] in
            try? self?.diskStorage.removeValue(for: key)
        }
    }
    
    public func removeAll() throws {
        memoryStorage.removeAll()
        
        ioQueue.async { [weak self] in
            try? self?.diskStorage.removeAll()
        }
    }
}

// MARK: - Helper methods

extension Cache {
    private static func createDefaultMemoryStorage() -> MemoryStorage<Key, Value> {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let costLimit = totalMemory / 4
        let memoryStorage = MemoryStorage<Key, Value>(config: .init(countLimit: 1000,
                                                                    totalCostLimit: (costLimit > Int.max) ? Int.max : Int(costLimit)))
        return memoryStorage
    }
    
    private static func createDefaultDiskStorage(name: String, cacheDirectoryURL: URL?) throws -> DiskStorage<Value> {
        // sizeLimit = 0 => no limit
        let config = DiskStorage<Value>.Config(name: name, sizeLimit: 0, directory: cacheDirectoryURL)
        let diskStorage = try DiskStorage<Value>(config: config)
        return diskStorage
    }
}
