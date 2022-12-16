//
//  AppDelegate.swift
//  Example-iOS
//
//  Created by Do Thang on 14/12/2022.
//

import UIKit
import Cache

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup ImageCache
        setupImageCache()
        
        return true
    }
    
    
    private func setupImageCache() {
        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 6
        ImageLoader.shared.config(cache: Cache(config: .init(countLimit: 100, memoryLimit: 100 * 1024 * 1024)),
                                  executeQueue: taskQueue,
                                  receiveQueue: .main)
    }
}

