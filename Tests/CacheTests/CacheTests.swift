import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    var cache: (any Cacheable<String, Int>)!
    var loader: ImageLoader!
    var sampleLoader: SampleLoader!
    
    override func setUpWithError() throws {
        // Init Cache
        cache = MemoryStorage(config: .init(countLimit: 5, totalCostLimit: 5 * 1024 * 1024))
        
        // Init ImageLoader
        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 6
        loader = ImageLoader(cache: Cache(name: "ImageLoader"),
                             config: .init(showLog: true, keepOnlyLatestHandler: false),
                             executeQueue: taskQueue, receiveQueue: .main)
        
        let taskQueue2 = OperationQueue()
        taskQueue2.maxConcurrentOperationCount = 6
        sampleLoader = SampleLoader(cache: Cache(name: "sampleLoader"),
                                    config: .init(showLog: true, keepOnlyLatestHandler: false),
                                    executeQueue: taskQueue2, receiveQueue: .main)
    }
    
    override func tearDownWithError() throws {
        try cache.removeAll()
        cache = nil
        sampleLoader = nil
    }
}

// MARK: - Cache

extension CacheTests {
    func testCache() throws {
        try cache.set(1, for: "Key1")
        try cache.set(2, for: "Key2")
        try cache.set(3, for: "Key3")
        try cache.set(4, for: "Key4")
        try cache.set(5, for: "Key5")
        try cache.set(6, for: "Key6")

        XCTAssert(try cache.value(for: "Key1") == nil)
        XCTAssert(try cache.value(for: "Key2") == 2)
        XCTAssert(try cache.value(for: "Key3") == 3)
        XCTAssert(try cache.value(for: "Key4") == 4)
        XCTAssert(try cache.value(for: "Key5") == 5)
        XCTAssert(try cache.value(for: "Key6") == 6)

        cache["Key1"] = 11
        try cache.set(7, for: "Key6")

        XCTAssert(try cache.value(for: "Key1") == 11)
        XCTAssert(try cache.value(for: "Key2") == nil)
        XCTAssert(cache["Key6"] == 7)
    }
}

// MARK: - Cache

extension CacheTests {
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

// MARK: - SampleLoader

extension CacheTests {
    func testSampleLoaderNested() {
        let waitExpectation = expectation(description: "Waiting")

        let sampleUrls = [
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
        ]
        
        let sampleUrls2 = [
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
        ]

        self.loadSamples(sampleUrls) {
            self.loadSamples(sampleUrls2) {
                waitExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }
    
    func testSampleLoaderRaceCondition() {
        let waitExpectation = expectation(description: "Waiting")

        let sampleUrls = [
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
            "https://tools.learningcontainer.com/sample-json.json",
        ]
        let concurrentQueue = DispatchQueue(label: "TestingSample", attributes: .concurrent)
        let maxBlockCount = 100

        for i in 0..<maxBlockCount {
            concurrentQueue.async {
                self.loadSamples(sampleUrls) {
                    if i == maxBlockCount - 1 {
                        waitExpectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
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
    
    private func loadSamples(_ sampleUrls: [String], completion: @escaping () -> Void) {
        var finishedCount = 0
        for urlString in sampleUrls {
            let url = URL(string: urlString)!
            self.sampleLoader.loadValue(from: url, key: url.absoluteString) { result, resultUrl in
                print("Finished Load Sample for: \(urlString)")
                switch result {
                case .success(let sample):
                    print("\(sample)")
                case .failure(let error):
                    print("\(error.localizedDescription)")
                }
                
                finishedCount += 1
                
                // Last url
                if finishedCount == sampleUrls.count {
                    completion()
                }
            }
        }
    }
}

class SampleLoader: BaseLoader<Sample> {
    static let shared = SampleLoader(cache: Cache(name: "SampleLoader.shared"),
                                     config: .init(showLog: false, keepOnlyLatestHandler: true),
                                     executeQueue: OperationQueue(),
                                     receiveQueue: .main)
    
    override init(cache: any Cacheable<Key, Sample>,
                  config: CacheLoaderConfig,
                  executeQueue: OperationQueue,
                  receiveQueue: OperationQueue = .main) {
        super.init(cache: cache, config: config, executeQueue: executeQueue, receiveQueue: receiveQueue)
    }
}

// Sample model for that json: https://tools.learningcontainer.com/sample-json.json
struct Sample: Codable {
    let firstName: String
    let lastName: String
    let gender: String
    let age: Int
}

extension Sample: DataTransformable {
    func toData() throws -> Data {
        let data = try JSONEncoder().encode(self)
        return data
    }
    
    static func fromData(_ data: Data) throws -> Sample? {
        return try? JSONDecoder().decode(Sample.self, from: data)
    }
}
