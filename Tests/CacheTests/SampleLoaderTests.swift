//
//  SampleLoaderTests.swift
//  
//
//  Created by Do Thang on 20/12/2022.
//

import XCTest
@testable import Cache

final class SampleLoaderTests: XCTestCase {
    var sampleLoader: SampleLoader!
    
    override func setUpWithError() throws {
        let taskQueue = OperationQueue()
        taskQueue.maxConcurrentOperationCount = 6
        sampleLoader = SampleLoader(cache: Cache(type: .cacheInfo(name: "SampleLoader"), config: .init(clearCacheType: .both)),
                                    config: .init(showLog: true, keepOnlyLatestHandler: false),
                                    executeQueue: taskQueue, receiveQueue: .main)
    }

    override func tearDownWithError() throws {
        try sampleLoader.removeCache()
        sampleLoader = nil
    }
}

// MARK: - SampleLoader

extension SampleLoaderTests {
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

extension SampleLoaderTests {
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
    static let shared = SampleLoader(cache: Cache(type: .cacheInfo(name: "SampleLoader.shared"), config: .init(clearCacheType: .both)),
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
