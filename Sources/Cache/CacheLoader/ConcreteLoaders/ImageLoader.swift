//
//  ImageLoader.swift
//  Cache
//
//  Created by Do Thang on 08/12/2022.
//

import UIKit

public class ImageLoader: BaseLoader<URL, UIImage> {
    public static let shared = ImageLoader(cache: Cache<URL, UIImage>(config: .init(countLimit: 50, memoryLimit: 50 * 1024 * 1024)),
                                           executeQueue: ImageLoader.defaultExecuteQueue(),
                                           receiveQueue: .main)
    
    public override func key(from url: URL) -> URL {
        return url
    }
    
    public override func value(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    private static func defaultExecuteQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 6
        return queue
    }
}
