//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Galih Samodra Wicaksono on 04/05/23.
//

import XCTest

class RemoteFeedLoader {
     
}

class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
    func test_init() {
        let client = HTTPClient()
        let sut = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }

}
