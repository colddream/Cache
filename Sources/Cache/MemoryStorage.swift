//
//  MemoryStorage.swift
//  Cache
//
//  Created by Do Thang on 19/12/2022.
//

import Foundation

/// Memory Storage Cache
public class MemoryStorage<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let config: Config
    private let lock = NSLock()
    
    public init(config: Config) {
        self.config = config
        wrapped.countLimit = config.countLimit
        wrapped.totalCostLimit = config.totalCostLimit
    }
}

// MARK: - Cacheable

extension MemoryStorage: Cacheable {
    public func set(_ value: Value, originalData: Data?, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        let entry = Entry(value: value)
        wrapped.setObject(entry, forKey: WrappedKey(key: key))
    }
    
    public func value(for key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        let entry = wrapped.object(forKey: WrappedKey(key: key))
        return entry?.value
    }
    
    public func removeValue(for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        wrapped.removeObject(forKey: WrappedKey(key: key))
    }
    
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        wrapped.removeAllObjects()
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return value(for: key)
        }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(for: key)
                return
            }

            try? set(value, for: key)
        }
    }
}

// MARK: - Define config

public extension MemoryStorage {
    struct Config {
        let countLimit: Int         // limit number of cache items
        let totalCostLimit: Int     // limit memory cache in bytes (100 * 1024 * 1024 = 100MB)
        
        public init(countLimit: Int, totalCostLimit: Int) {
            self.countLimit = countLimit
            self.totalCostLimit = totalCostLimit
        }
    }
}

// MARK: - Define Key and Value for NSCache

private extension MemoryStorage {
    final class WrappedKey: NSObject {
        let key: Key
        init(key: Key) {
            self.key = key
        }
        
        override var hash: Int {
            return key.hashValue
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let another = object as? WrappedKey else {
                return false
            }
            
            return self.key == another.key
        }
    }
    
    final class Entry {
        let value: Value
        init(value: Value) {
            self.value = value
        }
    }
}
