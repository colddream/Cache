import XCTest
@testable import Cache

final class CacheTests: XCTestCase {
    var cache: Cache<String, Int>!
    
    override func setUpWithError() throws {
        cache = Cache(config: .init(countLimit: 5, memoryLimit: 5 * 1024 * 1024))
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
}
