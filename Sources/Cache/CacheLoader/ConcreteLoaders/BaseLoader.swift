//
//  File.swift
//  Cache
//
//  Created by Do Thang on 14/12/2022.
//

import UIKit

/// We can extend this BaseLoader (instead of extending directly ImageLoader protocol) to avoid spending time to create boilerplate properties (cache, executeQueue, ...)
open class BaseLoader<Value: DataTransformable>: CacheLoader {
    public typealias Key = String
    // MARK: - CacheLoader methods
    
    public var cache: any Cacheable<Key, Value>
    
    public var config: CacheLoaderConfig
    
    public var executeQueue: OperationQueue
    
    public var receiveQueue: OperationQueue
    
    public var session: URLSession
    
    public var lock: NSLock = NSLock()
    
    public var safeQueue: DispatchQueue
    
    public var loadingUrls: [URL : Bool] = [:]
    
    public var pendingHandlers: [URL : [Handler]] = [:]
    
    // Init
    public init(cache: any Cacheable<Key, Value>,
                config: CacheLoaderConfig,
                executeQueue: OperationQueue,
                receiveQueue: OperationQueue = .main) {
        self.cache = cache
        self.config = config
        self.executeQueue = executeQueue
        self.receiveQueue = receiveQueue
        let prefix = String(describing: Self.self)
        self.safeQueue = DispatchQueue(label: "\(prefix)_LoaderSafeQueue", attributes: .concurrent)
        self.session = Self.regenerateSession(receiveQueue: receiveQueue)
    }
}
