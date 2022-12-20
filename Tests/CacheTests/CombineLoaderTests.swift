//
//  CombineLoaderTests.swift
//  
//
//  Created by Do Thang on 20/12/2022.
//

import XCTest
@testable import Cache

final class CombineLoaderTests: XCTestCase {
    var loader: ImageLoader!
    
    override func setUpWithError() throws {
        // Init ImageLoader
        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 6
        loader = ImageLoader(cache: Cache(name: "CombineLoader"),
                             config: .init(showLog: true, keepOnlyLatestHandler: false),
                             executeQueue: taskQueue, receiveQueue: .main)
    }

    override func tearDownWithError() throws {
        try loader.removeCache()
        loader = nil
    }
}


// MARK: - Image Loader

extension CombineLoaderTests {
    func testImageLoader() throws {
        let waitExpectation = expectation(description: "Waiting")

        self.loadImages {
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 50)
    }

    func testImageLoaderRaceCondition() throws {
        let waitExpectation = expectation(description: "Waiting")

        let concurrentQueue = DispatchQueue(label: "Testing", attributes: .concurrent)

        let maxBlockCount = 100

        for i in 0..<maxBlockCount {
            concurrentQueue.async {
                self.loadImages {
                    if i == maxBlockCount - 1 {
                        waitExpectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 80)
    }

    func testImageLoaderDeadLock() {
        let waitExpectation = expectation(description: "Waiting")
        let imageUrls = [
            "https://res.cloudinary.com/demo/basketball_shot.jpg",
            "https://res.cloudinary.com/demo/basketball_shot.jpg",
            "https://live.staticflickr.com/2912/13981352255_fc59cfdba2_b.jpg",
        ]
        let imageUrls2 = [
            "https://live.staticflickr.com/2912/13981352255_fc59cfdba2_b.jpg",
            "https://res.cloudinary.com/demo/image/upload/if_ar_gt_3:4_and_w_gt_300_and_h_gt_200,c_crop,w_300,h_200/sample.jpg"
        ]

        self.loadImages(imageUrls: imageUrls) {
            self.loadImages(imageUrls: imageUrls2) {
                waitExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 80)
    }
}


// MARK: - Helper methods

extension CombineLoaderTests {
    private func loadImages(completion: @escaping () -> Void) {
        let imageUrls = [
            //            "https://api.github.com/users/hadley/repos",
            //            "http://ip-api.com/json",
            //            "https://api.github.com/repositories/19438/commits",
            "https://res.cloudinary.com/demo/basketball_shot.jpg",
            "https://res.cloudinary.com/demo/basketball_shot.jpg",
            "https://live.staticflickr.com/2912/13981352255_fc59cfdba2_b.jpg",
            "https://res.cloudinary.com/demo/image/upload/if_ar_gt_3:4_and_w_gt_300_and_h_gt_200,c_crop,w_300,h_200/sample.jpg"
        ]
        loadImages(imageUrls: imageUrls, completion: completion)
    }
    
    private func loadImages(imageUrls: [String], completion: @escaping () -> Void) {
        var finishedCount = 0
        for urlString in imageUrls {
            let url = URL(string: urlString)!
            self.loader.loadValue(from: url, key: url.absoluteString) { result, resultUrl in
                print("Finished Load for: \(urlString)")
                switch result {
                case .success(let image):
                    print("\(image)")
                case .failure(let error):
                    print("\(error.localizedDescription)")
                }
                
                finishedCount += 1
                
                // Last url
                if finishedCount == imageUrls.count {
                    completion()
                }
            }
        }
    }
}
