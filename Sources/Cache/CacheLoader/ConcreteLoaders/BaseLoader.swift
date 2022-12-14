//
//  File.swift
//  Cache
//
//  Created by Do Thang on 14/12/2022.
//

import UIKit

/// We can extend this BaseLoader (instead of extending directly ImageLoader protocol) to avoid spending time to create boilerplate properties (cache, executeQueue, ...)
open class BaseLoader<Value>: CacheLoader {
    // MARK: - CacheLoader methods
    
    public var cache: any Cacheable<URL, Value>
    
    public var executeQueue: OperationQueue
    
    public var receiveQueue: OperationQueue
    
    public var session: URLSession
    
    public var loadingUrls: [URL : Bool] = [:]
    
    public var pendingHandlers: [URL : [Handler]] = [:]
    
    // Init
    public init(cache: any Cacheable<URL, Value>,
                executeQueue: OperationQueue,
                receiveQueue: OperationQueue = .main) {
        self.cache = cache
        self.executeQueue = executeQueue
        self.receiveQueue = receiveQueue
        self.session = Self.regenerateSession(receiveQueue: receiveQueue)
    }
    
    open func value(from data: Data) -> Value? {
        fatalError("Need to implement from sub class")
    }
}
