//
//  ImageLoader.swift
//  Cache
//
//  Created by Do Thang on 08/12/2022.
//

import UIKit

public class ImageLoader: BaseLoader<UIImage> {
    public static let shared = ImageLoader(cache: Cache<URL, UIImage>(config: .init(countLimit: 50, memoryLimit: 50 * 1024 * 1024)),
                                           executeQueue: ImageLoader.defaultExecuteQueue(),
                                           receiveQueue: .main)
    
    public override func value(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    private static func defaultExecuteQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 5
        return queue
    }
}
