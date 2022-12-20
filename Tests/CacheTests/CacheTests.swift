import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    var cache: (any Cacheable<String, Int>)!
    
    override func setUpWithError() throws {
        // Init Cache
        cache = MemoryStorage(config: .init(countLimit: 5, totalCostLimit: 5 * 1024 * 1024))
    }
    
    override func tearDownWithError() throws {
        try cache.removeAll()
        cache = nil
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
