import XCTest
import Domain
@testable import FeatureStore

final class SearchCacheTests: XCTestCase {

    func test_addQuery_dedupsAndCapsLimit() async {
        let cache = SearchCache(queriesLimit: 3, storesLimit: 3)
        await cache.addQuery("matcha")
        await cache.addQuery("uji")
        await cache.addQuery("MATCHA") // 대소문자 무시 dedupe
        await cache.addQuery("kyoto")
        await cache.addQuery("tokyo")  // overflow

        let q = await cache.queries()
        XCTAssertEqual(q.count, 3)
        XCTAssertEqual(q.first, "tokyo", "최신이 앞")
        XCTAssertFalse(q.contains(where: { $0.caseInsensitiveCompare("matcha") == .orderedSame }), "limit 초과로 밀려나감")
    }

    func test_addQuery_ignoresEmpty() async {
        let cache = SearchCache()
        await cache.addQuery("   ")
        await cache.addQuery("")
        let q = await cache.queries()
        XCTAssertEqual(q.count, 0)
    }

    func test_touchStore_dedupsAndCaps() async {
        let cache = SearchCache(storesLimit: 2)
        let r1 = SearchResult.preview(storeId: "1", name: "A")
        let r2 = SearchResult.preview(storeId: "2", name: "B")
        let r3 = SearchResult.preview(storeId: "3", name: "C")

        await cache.touchStore(r1)
        await cache.touchStore(r2)
        await cache.touchStore(r1)  // re-touch
        await cache.touchStore(r3)  // overflow

        let s = await cache.stores()
        XCTAssertEqual(s.count, 2)
        XCTAssertEqual(s[0].storeId, "3", "최신이 앞")
        XCTAssertEqual(s[1].storeId, "1")
    }

    func test_clearAndDefaults() async {
        let cache = SearchCache()
        await cache.addQuery("matcha")
        await cache.touchStore(.preview())
        XCTAssertGreaterThan(await cache.queries().count, 0)
        XCTAssertGreaterThan(await cache.stores().count, 0)

        await cache.clearQueries()
        await cache.clearStores()
        XCTAssertEqual(await cache.queries().count, 0)
        XCTAssertEqual(await cache.stores().count, 0)
    }
}
