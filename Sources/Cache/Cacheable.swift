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
    
    func set(_ value: Value, for key: Key)
    func value(for key: Key) -> Value?
    func removeValue(for key: Key)
    func removeAll()
    
    subscript(key: Key) -> Value? { get set }
}
