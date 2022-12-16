//
//  CacheLoader.swift
//  Cache
//
//  Created by Do Thang on 14/12/2022.
//

import UIKit

///
/// This protocol to support to get value (from data from the server's url) and cache using Cache
///
public protocol CacheLoader: AnyObject {
    associatedtype Key
    associatedtype Value
    typealias Handler = (Result<Value, Error>, URL) -> Void
    
    // Cache type to get/store value to cache
    var cache: any Cacheable<Key, Value> { get set }
    
    // queue that use to excute to data task operation
    var executeQueue: OperationQueue { get set }
    
    // queue that use for callback result (Ex: main queue)
    var receiveQueue: OperationQueue { get set }
    
    // session
    var session: URLSession { get set }
    
    // NOTE: this should be concurrent queue otherwise will crash or performance issue
    var safeQueue: DispatchQueue { get set }
    
    // This stores loading urls to use to avoid duplicate request
    var loadingUrls: [URL: Bool] { get set }
    
    // This stores pending handlers for the same url (Ex: we may call to load value from url more than one time)
    var pendingHandlers: [URL: [Handler]] { get set }
    
    // Get key from url
    func key(from url: URL) -> Key
    
    // Get value from data
    func value(from data: Data) -> Value?
}

extension CacheLoader {
    /// Regenerate session based on receiveQueue (Ex: main queue)
    /// - Parameter receiveQueue: queue for callback result of data task operation
    /// - Returns: return session
    public static func regenerateSession(receiveQueue: OperationQueue) -> URLSession {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: receiveQueue)
        return session
    }
}

// MARK: - public methods

extension CacheLoader {
    /// Config Loader with
    /// - Parameters:
    ///   - cache: cache type
    ///   - executeQueue: execute queue for data task operations
    ///   - receiveQueue: callback result queue
    public func config(cache: any Cacheable<Key, Value>,
                executeQueue: OperationQueue,
                receiveQueue: OperationQueue = .main) {
        // Make sure the old operations will be canceled
        self.executeQueue.cancelAllOperations()
        safeQueue.sync {
            self.pendingHandlers.removeAll()
            self.loadingUrls.removeAll()
        }
        
        // Setup again
        self.cache = cache
        self.executeQueue = executeQueue
        self.receiveQueue = receiveQueue
        self.session = Self.regenerateSession(receiveQueue: receiveQueue)
    }
    
    /// Load value from cache (or from server)
    /// - Parameters:
    ///   - url: url to load value
    ///   - keepOnlyLatestHandler: true => just keep the latest handler for pendingHandlers, otherwise keep all handlers
    ///   - isLog: log or not
    ///   - completion: handler
    public func loadValue(from url: URL,
                          keepOnlyLatestHandler: Bool = false,
                          isLog: Bool = false,
                          completion: @escaping Handler) {
        let key = self.key(from: url)
        if let value = cache[key] {
            receiveQueue.addOperation { [weak self] in
                self?.logPrint("[CacheLoader] value from cache (\(url.absoluteString))", isLog: isLog)
                completion(.success(value), url)
            }
            return
        }
        
        // Use async with .barrier is supper fast compare with using sync of concurent safeQueue
        // And this way also faster than using serial safeQueue sync/async
        safeQueue.async(flags: .barrier) {
            // Check if url is already loading
            if self.loadingUrls[url] == true {
                self.logPrint("[CacheLoader] waiting previous loading value", isLog: isLog)
                if keepOnlyLatestHandler {
                    self.pendingHandlers[url] = [completion]
                } else {
                    let preHandlers = self.pendingHandlers[url] ?? []
                    self.pendingHandlers[url] = preHandlers + [completion]
                }
                return
            }
            
            self.loadingUrls[url] = true
            self.pendingHandlers[url] = [completion]
            
            self.logPrint("[CacheLoader] Start get value from server (\(url.absoluteString))", isLog: isLog)
            let operation = DataTaskOperation(session: self.session, url: url) { [weak self] data, response, error in
                guard let self = self else {
                    return
                }
                
                let result: Result<Value, Error>
                
                if let error = error {
                    result = .failure(error)
                    
                } else if let data = data, let value = self.value(from: data) {
                    self.cache[key] = value
                    self.logPrint("[CacheLoader] value from server (\(url.absoluteString))", isLog: isLog)
                    result = .success(value)
                    
                } else {
                    let error = CustomError(message: "Invalid Value Data")
                    result = .failure(error)
                }
                
                self.handleResult(result, for: url)
            }
            self.executeQueue.addOperation(operation)
        }
    }
    
    public func cacheValue(for url: URL) -> Value? {
        return cache.value(for: key(from: url))
    }
    
    /// Remove all pending handlers that you don't want to notify to them anymore
    /// - Parameters:
    ///   - url: url to find pending handlers to remove
    ///   - keepLatestHandler: should keep latest handler or not
    public func removePendingHandlers(for url: URL, keepLatestHandler: Bool = false) {
        safeQueue.sync {
            if let handlers = self.pendingHandlers[url], handlers.count > 0 {
                if keepLatestHandler {
                    self.pendingHandlers[url] = [handlers.last!]
                } else {
                    self.pendingHandlers[url] = nil
                }
            }
        }
    }
    
    /// Cancel all operations
    public func cancelAll() {
        executeQueue.cancelAllOperations()
        safeQueue.sync {
            pendingHandlers.removeAll()
            loadingUrls.removeAll()
        }
    }
    
    /// Remove all cache values
    public func removeCache() {
        self.cache.removeAll()
    }
}

// MARK: - Helper methods

extension CacheLoader {
    /// Handle result of data task operations
    /// - Parameters:
    ///   - result: result to handle
    ///   - url: server url that using in data task  of the result
    private func handleResult(_ result: Result<Value, Error>, for url: URL) {
        var handlers: [Handler] = []
        safeQueue.sync {
            loadingUrls[url] = nil
            if pendingHandlers[url] == nil {
                return
            }
            
            handlers = pendingHandlers[url]!
            pendingHandlers[url] = nil
        }
        
        handlers.forEach { $0(result, url) }
    }
    
    /// Log
    private func logPrint(_ items: Any..., separator: String = " ", terminator: String = "\n", isLog: Bool) {
        if isLog {
            print(items, separator: separator, terminator: terminator)
        }
    }
}
