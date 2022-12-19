//
//  CustomError.swift
//  Cache
//
//  Created by Do Thang on 08/12/2022.
//

import Foundation

public struct CustomError: LocalizedError {
    let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public var errorDescription: String? {
        return [message.isEmpty ? nil : message, "Unknown Error."].compactMap { $0 }.first
    }
}

public enum CacheError: LocalizedError {
    case cacheError(reason: CacheErrorReason)
    case other(String)
    
    public var errorDescription: String? {
        switch self {
        case let .cacheError(reason):
            return reason.errorDescription
        case let .other(message):
            return message
        }
    }
}

extension CacheError {
    public enum CacheErrorReason {
        /// Cannot create a file enumerator for a certain disk URL. Code 3001.
        /// - url: The target disk URL from which the file enumerator should be created.
        case fileEnumeratorCreationFailed(url: URL)
        
        /// Cannot get correct file contents from a file enumerator. Code 3002.
        /// - url: The target disk URL from which the content of a file enumerator should be got.
        case invalidFileEnumeratorContent(url: URL)
        
        /// The file at target URL exists, but the data cannot be loaded from it. Code 3004.
        /// - url: The disk URL where the target cached file exists.
        /// - error: The underlying error which describes why this error happens.
        case cannotLoadDataFromDisk(url: URL, error: Error)
        
        /// Cannot create a folder at a given path. Code 3005.
        /// - path: The disk path where the directory creating operation fails.
        /// - error: The underlying error which describes why this error happens.
        case cannotCreateDirectory(path: String, error: Error)
        
        /// Cannot convert an object to data for storing. Code 3007.
        /// - object: The object which needs be convert to data.
        case cannotConvertToData(object: Any, error: Error)
        
        
        /// Cannot create the cache file at a certain fileURL under a key. Code 3009.
        /// - fileURL: The url where the cache file should be created.
        /// - key: The cache key used for the cache. When caching a file through `KingfisherManager` and Kingfisher's
        ///        extension method, it is the resolved cache key based on your input `Source` and the image processors.
        /// - data: The data to be cached.
        /// - error: The underlying error originally thrown by Foundation when writing the `data` to the disk file at
        ///          `fileURL`.
        case cannotCreateCacheFile(fileURL: URL, key: String, data: Data, error: Error)
    }
}

extension CacheError.CacheErrorReason {
    var errorDescription: String? {
        switch self {
        case .fileEnumeratorCreationFailed(let url):
            return "Cannot create file enumerator for URL: \(url)."
        case .invalidFileEnumeratorContent(let url):
            return "Cannot get contents from the file enumerator at URL: \(url)."
        case .cannotLoadDataFromDisk(let url, let error):
            return "Cannot load data from disk at URL: \(url). Underlying error: \(error)"
        case let .cannotCreateDirectory(path, error):
            return "Cannot create directory at given path: Path: \(path). Underlying error: \(error)"
        case let .cannotConvertToData(object, error):
            return "Cannot convert the input object to a `Data` object when storing it to disk cache. " +
                   "Object: \(object). Underlying error: \(error)"
        case .cannotCreateCacheFile(let fileURL, let key, let data, let error):
            return "Cannot create cache file at url: \(fileURL), key: \(key), data length: \(data.count). " +
                   "Underlying foundation error: \(error)."
        }
    }
    
    var errorCode: Int {
        switch self {
        case .fileEnumeratorCreationFailed: return 3001
        case .invalidFileEnumeratorContent: return 3002
        case .cannotLoadDataFromDisk: return 3004
        case .cannotCreateDirectory: return 3005
        case .cannotConvertToData: return 3007
        case .cannotCreateCacheFile: return 3009
        }
    }
}
