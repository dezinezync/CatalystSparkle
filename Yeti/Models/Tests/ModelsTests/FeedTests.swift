//
//  FeedTests.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import XCTest
@testable import Models

final class FeedTests: XCTestCase {
    
    static let feedJSON: [String: Any]? = {
        guard let data = feedJSONString.data(using: .utf8) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }()
    
    static func makeFeed () -> Feed {
        return Feed(from: Self.feedJSON!)
    }
    
    func testInitFromDict () {
        
        let feed = Self.makeFeed()
        
        XCTAssertEqual(feed.feedID, 1)
        XCTAssert(feed.summary.contains("Apple news"))
        XCTAssertEqual(feed.title, "MacStories")
        XCTAssert(feed.url.absoluteString.contains("/feed"))
        XCTAssertEqual(feed.rpcCount, 0)
        XCTAssertNil(feed.lastRPC)
        XCTAssertFalse(feed.hubSubscribed)
        XCTAssertEqual(feed.folderID, 0)
        XCTAssertNotNil(feed.extra)
        XCTAssertNotNil(feed.extra?.opengraph)
        XCTAssert(feed.canShowExtraLevel == true)
        XCTAssertEqual(feed.displayTitle, feed.title)
        
        feed.setValue("2021-03-04T00:00:00.000Z", forKey: "lastRPC")
        XCTAssertNotNil(feed.lastRPC)
        
    }
    
    func testEquality () {
        
        let feed = Self.makeFeed()
        
        let shallowCopy = Feed()
        shallowCopy.feedID = feed.feedID
        shallowCopy.url = feed.url
        
        XCTAssert(feed == shallowCopy)
        
        shallowCopy.feedID += 1
        
        XCTAssert(feed != shallowCopy)
        
        XCTAssert(feed != FeedMetaData())
        
    }
    
    func testDictRepresentation () {
        
        let feed = Self.makeFeed()
        
        let dict = feed.dictionaryRepresentation
        
        XCTAssertNotNil(dict["extra"])
        XCTAssertNotNil(dict["title"])
        XCTAssertNotNil(dict["url"])
        XCTAssertNotNil(dict["feedID"])
        
    }
    
    func testDescription () {
        
        let feed = Self.makeFeed()
        let desc = feed.description
        
        XCTAssert(desc.contains("Feed:"))
        XCTAssert(desc.contains("macstories.net"))
        
    }

}

private let feedJSONString = "{\"id\":1,\"extra\":{\"opengraph\":{\"locale\":\"en_US\",\"type\":\"website\",\"title\":\"MacStories\",\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"url\":\"https://www.macstories.net\",\"image\":\"https://56243e3f6f46fe44a301-deabeb5f3878e3553d0b065ea974f9bf.ssl.cf1.rackcdn.com/256px.png\"},\"apple-touch-icon\":{\"76\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-76x76-precomposed.png\",\"120\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-120x120-precomposed.png\",\"152\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-152x152-precomposed.png\",\"256\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-precomposed.png\"},\"feedlinks\":[\"https://www.macstories.net/feed/json/\",\"https://www.macstories.net/feed/\",\"https://www.macstories.net/?feed=articles-only\"],\"keywords\":[\"iOS\",\"iPhone apps\",\"iPad apps\",\"Mac applications\",\"OS X\",\"Apple news\",\"rumors\",\"MacStories\"],\"title\":\"MacStories\",\"feeds\":[{\"title\":\"MacStories » JSON Feed\",\"type\":\"application/feed+json\",\"url\":\"https://www.macstories.net/feed/json/\"},{\"title\":\"MacStories\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/feed/\"},{\"title\":\"MacStories — Articles Only\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/?feed=articles-only\"}],\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"icon\":\"https://www.macstories.net/app/themes/macstories4/images/favicon.png\",\"url\":\"https://www.macstories.net\"},\"modified\":\"2020-10-13T06:12:35.000Z\",\"hubSubscribed\":0,\"hubLease\":null,\"subscribed\":false,\"url\":\"https://www.macstories.net/feed/json\",\"title\":\"MacStories\",\"rpcCount\":null,\"summary\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"podcast\":0,\"explicit\":0,\"created\":\"2017-11-13T04:43:43.000Z\",\"favicon\":\"\",\"hub\":null,\"lastRPC\":null,\"flags\":null,\"status\":1}"
