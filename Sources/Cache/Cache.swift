//
//  Cache.swift
//  Cache
//
//  Created by Do Thang on 11/12/2022.
//

import Foundation

public class Cache<Key: Hashable, Value> {
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let config: Config
    
    public init(config: Config) {
        self.config = config
        wrapped.countLimit = config.countLimit
        wrapped.totalCostLimit = config.memoryLimit
    }
}

// MARK: - Cacheable

extension Cache: Cacheable {
    public func set(_ value: Value, for key: Key) {
        if config.showLog {
            print("Set value: \(value) for key: \(key)")
        }
        
        let entry = Entry(value: value)
        wrapped.setObject(entry, forKey: WrappedKey(key: key))
    }
    
    public func value(for key: Key) -> Value? {
        if config.showLog {
            print("Get value for key: \(key)")
        }
        
        let entry = wrapped.object(forKey: WrappedKey(key: key))
        return entry?.value
    }
    
    public func removeValue(for key: Key) {
        if config.showLog {
            print("Remove value for key: \(key)")
        }
        
        wrapped.removeObject(forKey: WrappedKey(key: key))
    }
    
    public func removeAll() {
        if config.showLog {
            print("Remove All")
        }
        
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

            set(value, for: key)
        }
    }
}

// MARK: - Define config

public extension Cache {
    struct Config {
        let countLimit: Int     // limit number of cache items
        let memoryLimit: Int    // limit memory cache in bytes (100 * 1024 * 1024 = 100MB)
        let showLog: Bool       // To show log or not
        
        public init(countLimit: Int, memoryLimit: Int, showLog: Bool = false) {
            self.countLimit = countLimit
            self.memoryLimit = memoryLimit
            self.showLog = showLog
        }
    }
}

// MARK: - Define Key and Value for NSCache

private extension Cache {
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
