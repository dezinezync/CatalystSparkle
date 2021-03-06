//
//  FeedMetaDataTests.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import XCTest
@testable import Models

final class FeedMetaDataTests: XCTestCase {
    
    static func makeMetadata() -> FeedMetaData? {
        
        guard let data = feedMetaJSONString.data(using: .utf8) else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return FeedMetaData(from: json)
        
    }
    
    func testInitFromDict () {
        
        let feed = Self.makeMetadata()!
        
        XCTAssertEqual(feed.icons.count, 4)
        XCTAssertNil(feed.icon)
        XCTAssertNotNil(feed.keywords)
        XCTAssert(feed.keywords.count > 0)
        XCTAssertNotNil(feed.title)
        XCTAssertNotNil(feed.summary)
        XCTAssertNotNil(feed.opengraph)
        
    }
    
    func testDictRepresentation () {
        
        let feed = Self.makeMetadata()!
        let dict = feed.dictionaryRepresentation
        
        XCTAssertEqual(feed.icons.count, (dict["icons"] as? [String: Any])?.count)
        XCTAssertNil(dict["icon"])
        XCTAssertNotNil(dict["keywords"])
        XCTAssert((dict["keywords"] as! [String]).count > 0)
        XCTAssertEqual(feed.title, dict["title"] as? String)
        XCTAssertNotNil(dict["summary"])
        XCTAssertNotNil(dict["opengraph"])
        XCTAssertEqual(feed.opengraph?.dictionaryRepresentation as? [String: String], dict["opengraph"] as? [String: String])
        
    }
    
    func testSettingURLasURL() {
        
        let feed = FeedMetaData()
        feed.setValue(URL(string: "https://elytra.app/"), forKey: "url")
        
        XCTAssertNotNil(feed.url)
        
    }
    
    func testSettingIconasURL() {
        
        let feed = FeedMetaData()
        feed.setValue(URL(string: "https://elytra.app/favicon.png"), forKey: "icon")
        
        XCTAssertNotNil(feed.icon)
        
    }
    
    func testSettingKeywordsAsString() {
        
        let feed = FeedMetaData()
        feed.setValue("singleKeyword", forKey: "keywords")
        
        XCTAssertNotNil(feed.keywords)
        XCTAssertEqual(feed.keywords.count, 1)
        XCTAssertEqual(feed.keywords.first, "singleKeyword")
        
    }
    
    func testSettingKeywordsAsComponentString() {
        
        let feed = FeedMetaData()
        feed.setValue("firstKeyword, secondKeyword", forKey: "keywords")
        
        XCTAssertNotNil(feed.keywords)
        XCTAssertEqual(feed.keywords.count, 2)
        XCTAssertEqual(feed.keywords.first, "firstKeyword")
        XCTAssertEqual(feed.keywords.last, "secondKeyword")
        
    }
    
}

private let feedMetaJSONString = "{\"opengraph\":{\"locale\":\"en_US\",\"type\":\"website\",\"title\":\"MacStories\",\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"url\":\"https://www.macstories.net\",\"image\":\"https://56243e3f6f46fe44a301-deabeb5f3878e3553d0b065ea974f9bf.ssl.cf1.rackcdn.com/256px.png\"},\"apple-touch-icon\":{\"76\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-76x76-precomposed.png\",\"120\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-120x120-precomposed.png\",\"152\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-152x152-precomposed.png\",\"256\":\"https://www.macstories.net/app/themes/macstories4/images/apple-touch-icon-precomposed.png\"},\"feedlinks\":[\"https://www.macstories.net/feed/json/\",\"https://www.macstories.net/feed/\",\"https://www.macstories.net/?feed=articles-only\"],\"keywords\":[\"iOS\",\"iPhone apps\",\"iPad apps\",\"Mac applications\",\"OS X\",\"Apple news\",\"rumors\",\"MacStories\"],\"title\":\"MacStories\",\"feeds\":[{\"title\":\"MacStories » JSON Feed\",\"type\":\"application/feed+json\",\"url\":\"https://www.macstories.net/feed/json/\"},{\"title\":\"MacStories\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/feed/\"},{\"title\":\"MacStories — Articles Only\",\"type\":\"application/rss+xml\",\"url\":\"https://www.macstories.net/?feed=articles-only\"}],\"summary\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\"}"
