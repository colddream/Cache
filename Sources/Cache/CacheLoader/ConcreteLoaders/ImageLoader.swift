//
//  ImageLoader.swift
//  Cache
//
//  Created by Do Thang on 08/12/2022.
//

import UIKit

public class ImageLoader: BaseLoader<UIImage> {
    public static let shared = ImageLoader(cache: Cache(type: .cacheInfo(name: "ImageLoader.shared", cacheDirectoryUrl: nil), config: .init(clearCacheType: .both)),
                                           config: .init(),
                                           executeQueue: ImageLoader.defaultExecuteQueue(),
                                           receiveQueue: .main)
    
    private static func defaultExecuteQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 6
        return queue
    }
}

// MARK: UIImage - DataTransformable
extension UIImage: DataTransformable {
    public func toData() throws -> Data {
        let data: Data?
        if let cgImage = self.cgImage, cgImage.renderingIntent == .defaultIntent {
            data = self.jpegData(compressionQuality: 1.0)
        } else {
            data = self.pngData()
        }
        
        if let data = data {
            return data
        }
        
        throw CustomError(message: "Cannot convert UIImage to data")
    }
    
    public static func fromData(_ data: Data) throws -> Self? {
        return UIImage(data: data) as? Self
    }
}
