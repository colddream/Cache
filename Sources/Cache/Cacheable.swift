//
//  Cacheable.swift
//  Cache
//
//  Created by Do Thang on 11/12/2022.
//

import Foundation

/// Cacheable protocol
public protocol Cacheable<Key, Value> {
    associatedtype Key
    associatedtype Value
    
    // originalData that preresent for value
    // => for some reasons we need to convert value to data before caching (Ex: disk cache)
    // => So using exist originalData to avoiding cost/time to convert from value to data
    func set(_ value: Value, originalData: Data?, for key: Key) throws
    func set(_ value: Value, for key: Key) throws
    func value(for key: Key) throws -> Value?
    func removeValue(for key: Key) throws
    func removeAll() throws
    
    subscript(key: Key) -> Value? { get set }
}

extension Cacheable {
    public func set(_ value: Value, for key: Key) throws {
        try set(value, originalData: nil, for: key)
    }

    public subscript(key: Key) -> Value? {
        get {
            return try? value(for: key)
        }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                try? removeValue(for: key)
                return
            }

            try? set(value, for: key)
        }
    }
}
