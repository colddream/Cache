//
//  DiskStorage.swift
//  Cache
//
//  Created by Do Thang on 19/12/2022.
//

import Foundation

public class DiskStorage<Value: DataTransformable> {
    public typealias Key = String
    
    /// The config used for this disk storage.
    public let config: Config
    
    // The final storage URL on disk
    public let directoryURL: URL
    
    /// Creates a disk storage with the given `DiskStorage.Config`.
    ///
    /// - Parameter config: The config used for this disk storage.
    /// - Throws: An error if the folder for storage cannot be got or created.
    init(config: Config) throws {
        self.config = config
        self.directoryURL = config.createFinalDirectoryUrl()
        try prepareDirectory()
    }
}

// MARK: - Cacheable

extension DiskStorage: Cacheable {
    public func set(_ value: Value, for key: Key) throws {
        // Generate data from value
        let data: Data
        do {
            data = try value.toData()
        } catch {
            throw CacheError.cacheError(reason: .cannotConvertToData(object: value, error: error))
        }
        
        // Generate cache File Url and write data to this file url
        let fileURL = cacheFileURL(forKey: key)
        do {
            // FIXME: - consider update witeOptions
            let writeOptions: Data.WritingOptions = []
            try data.write(to: fileURL, options: writeOptions)
        } catch {
            throw CacheError.cacheError(reason: .cannotCreateCacheFile(fileURL: fileURL, key: key, data: data, error: error))
        }
    }
    
    public func value(for key: Key) throws -> Value? {
        let fileManager = config.fileManager
        let fileURL = cacheFileURL(forKey: key)
        let filePath = fileURL.path
        
        guard fileManager.fileExists(atPath: filePath) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let obj = try Value.fromData(data)
            return obj
        } catch {
            throw CacheError.cacheError(reason: .cannotLoadDataFromDisk(url: fileURL, error: error))
        }
    }
    
    public func removeValue(for key: Key) throws {
        let fileURL = cacheFileURL(forKey: key)
        try config.fileManager.removeItem(at: fileURL)
    }
    
    public func removeAll() throws {
        try removeAll(skipCreatingDirectory: false)
    }
}

// MARK: - Helper methods

extension DiskStorage {
    /// Creates the storage folder
    private func prepareDirectory() throws {
        let fileManager = config.fileManager
        let path = directoryURL.path
        
        guard !fileManager.fileExists(atPath: path) else { return }
        
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil)
        } catch {
            throw CacheError.cacheError(reason: .cannotCreateDirectory(path: path, error: error))
        }
    }
    
    /// The URL of the cached file with a given computed `key`
    ///
    /// - Parameter key: The final computed key used when caching the image. Please note that usually this is not
    /// the `cacheKey` of an image `Source`. It is the computed key with processor identifier considered.
    ///
    /// - Note:
    /// This method does not guarantee there is an image already cached in the returned URL. It just gives your
    /// the URL that the image should be if it exists in disk storage, with the give key.
    ///
    private func cacheFileURL(forKey key: String) -> URL {
        let fileName = cacheFileName(forKey: key)
        return directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
    
    private func cacheFileName(forKey key: String) -> String {
        if config.usesHashedFileName {
            let hashedKey = key.md5
            if let ext = config.pathExtension {
                return "\(hashedKey).\(ext)"
            } else if config.autoExtAfterHashedFileName, let ext = key.ext {
                return "\(hashedKey).\(ext)"
            }
            return hashedKey
        } else {
            if let ext = config.pathExtension {
                return "\(key).\(ext)"
            }
            return key
        }
    }
    
    /// Removes all size exceeded values from this storage.
    /// - Throws: A file manager error during removing the file.
    /// - Returns: The URLs for removed files.
    ///
    /// - Note: This method checks `config.sizeLimit` and remove cached files in an LRU (Least Recently Used) way.
    func removeSizeExceededValues() throws -> [URL] {
        
        if config.sizeLimit == 0 { return [] } // Back compatible. 0 means no limit.
        
        var size = try totalSize()
        if size < config.sizeLimit { return [] }
        
        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .creationDateKey,
            .fileSizeKey
        ]
        let keys = Set(propertyKeys)
        
        let urls = try allFileURLs(for: propertyKeys)
        var pendings: [FileMeta] = urls.compactMap { fileURL in
            guard let meta = try? FileMeta(fileURL: fileURL, resourceKeys: keys) else {
                return nil
            }
            return meta
        }
        // Sort by last access date. Most recent file first.
        pendings.sort(by: FileMeta.lastAccessDate)
        
        var removed: [URL] = []
        let target = config.sizeLimit / 2
        while size > target, let meta = pendings.popLast() {
            size -= UInt(meta.fileSize)
            try removeFile(at: meta.url)
            removed.append(meta.url)
        }
        return removed
    }
    
    /// Remove file at url
    func removeFile(at url: URL) throws {
        try config.fileManager.removeItem(at: url)
    }
    
    /// Gets the total file size of the folder in bytes.
    public func totalSize() throws -> UInt {
        let propertyKeys: [URLResourceKey] = [.fileSizeKey]
        let urls = try allFileURLs(for: propertyKeys)
        let keys = Set(propertyKeys)
        let totalSize: UInt = urls.reduce(0) { size, fileURL in
            do {
                let meta = try FileMeta(fileURL: fileURL, resourceKeys: keys)
                return size + UInt(meta.fileSize)
            } catch {
                return size
            }
        }
        return totalSize
    }
    
    private func removeAll(skipCreatingDirectory: Bool) throws {
        try config.fileManager.removeItem(at: directoryURL)
        if !skipCreatingDirectory {
            try prepareDirectory()
        }
    }
    
    private func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {
        let fileManager = config.fileManager
        
        guard let directoryEnumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else {
            throw CacheError.cacheError(reason: .fileEnumeratorCreationFailed(url: directoryURL))
        }
        
        guard let urls = directoryEnumerator.allObjects as? [URL] else {
            throw CacheError.cacheError(reason: .invalidFileEnumeratorContent(url: directoryURL))
        }
        return urls
    }
}

// MARK: Pre-define

extension DiskStorage {
    
    /// Represents the config used in a `DiskStorage`.
    public struct Config {
        /// The file size limit on disk of the storage in bytes. 0 means no limit.
        public var sizeLimit: UInt
        
        /// The preferred extension of cache item. It will be appended to the file name as its extension.
        /// Default is `nil`, means that the cache file does not contain a file extension.
        public var pathExtension: String? = nil
        
        /// Default is `true`, means that the cache file name will be hashed before storing.
        public var usesHashedFileName = true
        
        /// Default is `false`
        /// If set to `true`, image extension will be extracted from original file name and append to
        /// the hased file name and used as the cache key on disk.
        public var autoExtAfterHashedFileName = false
        
        let name: String
        let fileManager: FileManager
        let directory: URL?
        
        /// Creates a config value based on given parameters.
        ///
        /// - Parameters:
        ///   - name: The name of cache. It is used as a part of storage folder. It is used to identify the disk
        ///           storage. Two storages with the same `name` would share the same folder in disk, and it should
        ///           be prevented.
        ///   - sizeLimit: The size limit in bytes for all existing files in the disk storage.
        ///   - fileManager: The `FileManager` used to manipulate files on disk. Default is `FileManager.default`.
        ///   - directory: The URL where the disk storage should live. The storage will use this as the root folder,
        ///                and append a path which is constructed by input `name`. Default is `nil`, indicates that
        ///                the cache directory under user domain mask will be used.
        public init(name: String, sizeLimit: UInt,
                    fileManager: FileManager = .default, directory: URL? = nil) {
            self.name = name
            self.fileManager = fileManager
            self.directory = directory
            self.sizeLimit = sizeLimit
        }
        
        func createFinalDirectoryUrl() -> URL {
            let rootUrl: URL
            if let directory = self.directory {
                rootUrl = directory
            } else {
                rootUrl = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            }
            
            let cacheName = "com.ipro.Cache.\(name)"
            let finalURL = rootUrl.appendingPathComponent(cacheName, isDirectory: true)
            return finalURL
        }
    }
    
    struct FileMeta {
        let url: URL
        let lastAccessDate: Date?
        let estimatedExpirationDate: Date?
        let isDirectory: Bool
        let fileSize: Int
        
        static func lastAccessDate(lhs: FileMeta, rhs: FileMeta) -> Bool {
            return lhs.lastAccessDate ?? .distantPast > rhs.lastAccessDate ?? .distantPast
        }
        
        init(fileURL: URL, resourceKeys: Set<URLResourceKey>) throws {
            let meta = try fileURL.resourceValues(forKeys: resourceKeys)
            self.init(
                fileURL: fileURL,
                lastAccessDate: meta.creationDate,
                estimatedExpirationDate: meta.contentModificationDate,
                isDirectory: meta.isDirectory ?? false,
                fileSize: meta.fileSize ?? 0)
        }
        
        init(fileURL: URL, lastAccessDate: Date?,
             estimatedExpirationDate: Date?, isDirectory: Bool, fileSize: Int) {
            self.url = fileURL
            self.lastAccessDate = lastAccessDate
            self.estimatedExpirationDate = estimatedExpirationDate
            self.isDirectory = isDirectory
            self.fileSize = fileSize
        }
    }
}
