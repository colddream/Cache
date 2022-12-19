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
    
    func set(_ value: Value, for key: Key) throws
    func value(for key: Key) throws -> Value?
    func removeValue(for key: Key) throws
    func removeAll() throws
    
    subscript(key: Key) -> Value? { get set }
}

extension Cacheable {
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
