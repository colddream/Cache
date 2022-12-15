import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    var cache: (any Cacheable<String, Int>)!
    var loader: ImageLoader!
    
    override func setUpWithError() throws {
        // Init Cache
        cache = Cache(config: .init(countLimit: 5, memoryLimit: 5 * 1024 * 1024))
        
        // Init ImageLoader
        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 1
        loader = ImageLoader.shared
        loader.config(cache: Cache(config: .init(countLimit: 100, memoryLimit: 100 * 1024 * 1024)),
                           executeQueue: taskQueue,
                           receiveQueue:.main)
    }
    
    override func tearDownWithError() throws {
        cache.removeAll()
        cache = nil
    }
    
    func testCache() throws {
        cache.set(1, for: "Key1")
        cache.set(2, for: "Key2")
        cache.set(3, for: "Key3")
        cache.set(4, for: "Key4")
        cache.set(5, for: "Key5")
        cache.set(6, for: "Key6")
        
        XCTAssert(cache.value(for: "Key1") == nil)
        XCTAssert(cache.value(for: "Key2") == 2)
        XCTAssert(cache.value(for: "Key3") == 3)
        XCTAssert(cache.value(for: "Key4") == 4)
        XCTAssert(cache.value(for: "Key5") == 5)
        XCTAssert(cache.value(for: "Key6") == 6)
        
        cache.set(11, for: "Key1")
        cache.set(7, for: "Key6")
        
        XCTAssert(cache.value(for: "Key1") == 11)
        XCTAssert(cache.value(for: "Key2") == nil)
        XCTAssert(cache.value(for: "Key6") == 7)        
    }
    
    func testImageLoader() throws {
        let waitExpectation = expectation(description: "Waiting")

        self.loadImages {
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
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

extension CacheTests {
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
            self.loader.loadValue(from: URL(string: urlString)!, keepOnlyLatestHandler: false, isLog: true) { result, resultUrl in
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
