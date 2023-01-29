//
//  Cache.swift
//  Cache
//
//  Created by Do Thang on 11/12/2022.
//

import Foundation

/// Cache class that using both memory and disk for caching
public class Cache<Value: DataTransformable> {
    
    // MARK: - Storages
    public let memoryStorage: MemoryStorage<Key, Value>
    public let diskStorage: DiskStorage<Value>
    private let ioQueue: DispatchQueue
    private let config: Config
    
    // MARK: Initializers
    
    /// Creates an `Cache` from a config.
    ///
    /// - Parameters:
    ///   - memoryStorage: The `MemoryStorage.Backend` object to use in the image cache.
    ///   - diskStorage: The `DiskStorage.Backend` object to use in the image cache.
    public init(type: InitType, config: Config) {
        let ioQueueName = "com.ipro.Cache.ioQueue.\(UUID().uuidString)"
        self.ioQueue = DispatchQueue(label: ioQueueName, attributes: .concurrent)
        self.config = config
        
        switch type {
        case let .storages(memory, disk):
            self.memoryStorage = memory
            self.diskStorage = disk
        case let .cacheInfo(name, cacheDirectoryUrl):
            if name.isEmpty {
                fatalError("[Cache] You should specify a name for the cache. A cache with empty name is not permitted.")
            }
            
            // Create default memory storage
            let memoryStorage = Self.createDefaultMemoryStorage()
            self.memoryStorage = memoryStorage
            
            // Create default disk storage
            do {
                let diskStorage = try Self.createDefaultDiskStorage(name: name, cacheDirectoryURL: cacheDirectoryUrl)
                self.diskStorage = diskStorage
            } catch {
                fatalError("[Cache] \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Cacheable

extension Cache: Cacheable {
    public func set(_ value: Value, originalData: Data?, for key: Key) throws {
        memoryStorage.set(value, originalData: originalData, for: key)
        
        ioQueue.async { [weak self] in
            try? self?.diskStorage.set(value, originalData: originalData, for: key)
        }
    }
    
    public func value(for key: Key) throws -> Value? {
        if let value = memoryStorage.value(for: key) {
            logPrint("[Cache] value from memory")
            return value
        }
        
        // Get value from disk
        var value: Value?
        ioQueue.sync {
            value = try? diskStorage.value(for: key)
        }
        
        // If exist value from disk => store to memory cache to use later
        if value != nil {
            logPrint("[Cache] value from disk")
            try memoryStorage.set(value!, for: key)
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
        switch config.clearCacheType {
        case .both:
            print("[Cache] Remove Cache from both memory and disk")
            memoryStorage.removeAll()
            ioQueue.async { [weak self] in
                try? self?.diskStorage.removeAll()
            }
        case .memoryOnly:
            print("[Cache] Remove Cache from memory only")
            memoryStorage.removeAll()
        case .diskOnly:
            print("[Cache] Remove Cache from disk only")
            ioQueue.async { [weak self] in
                try? self?.diskStorage.removeAll()
            }
        }
    }
}

// MARK: - Helper methods

extension Cache {
    private static func createDefaultMemoryStorage() -> MemoryStorage<Key, Value> {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let costLimit = totalMemory / 4     //  costLimit = total ram of device / 4
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
    
    /// Log
    private func logPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if config.showLog {
            print(items, separator: separator, terminator: terminator)
        }
    }
}

// MARK: - Predefines

extension Cache {
    public enum InitType {
        case storages(memory: MemoryStorage<Key, Value>, disk: DiskStorage<Value>)
        case cacheInfo(name: String, cacheDirectoryUrl: URL? = nil)
    }
    
    public struct Config {
        public enum ClearCacheType {
            case memoryOnly
            case diskOnly
            case both
        }
        
        public let clearCacheType: ClearCacheType
        public let showLog: Bool
        
        public init(clearCacheType: ClearCacheType, showLog: Bool = false) {
            self.clearCacheType = clearCacheType
            self.showLog = showLog
        }
    }
    
    public typealias Key = String
    /// Closure that defines the disk cache path from a given path and cacheName.
    public typealias DiskCachePathClosure = (URL, String) -> URL
}
