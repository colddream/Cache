//
//  SampleLoader.swift
//  Example-iOS
//
//  Created by Do Thang on 14/12/2022.
//

import UIKit
import Cache

class SampleLoader: BaseLoader<URL, Sample> {
    static let shared = SampleLoader(cache: Cache<URL, Sample>(config: .init(countLimit: 100, memoryLimit: 50 * 1024 * 1024)),
                                     executeQueue: OperationQueue(),
                                     receiveQueue: .main)
    
    override func value(from data: Data) -> Sample? {
        return Sample()
    }
    
    override init(cache: any Cacheable<URL, Sample>, executeQueue: OperationQueue, receiveQueue: OperationQueue = .main) {
        super.init(cache: cache, executeQueue: executeQueue, receiveQueue: receiveQueue)
    }
}

struct Sample: Codable {
}
