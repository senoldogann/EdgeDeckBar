import Foundation
import XCTest
@testable import EdgeDeck

final class LinkValidationTests: XCTestCase {
    func testNormalizedLink() {
        // 1. https remains https
        let httpsResult = normalizedLink(raw: "https://example.com")
        XCTAssertEqual(httpsResult, .success(URL(string: "https://example.com")!))

        // 2. bare host normalizes to https
        let bareResult = normalizedLink(raw: "example.com")
        XCTAssertEqual(bareResult, .success(URL(string: "https://example.com")!))

        // 3. whitespace fails
        let whitespaceResult = normalizedLink(raw: "   \t  ")
        XCTAssertEqual(whitespaceResult, .failure(.empty))

        // 4. unsupported schemes fail
        let ftpResult = normalizedLink(raw: "ftp://example.com/file")
        XCTAssertEqual(ftpResult, .failure(.unsupportedScheme("ftp")))
    }
}
