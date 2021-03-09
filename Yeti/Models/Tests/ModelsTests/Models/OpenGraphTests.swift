//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import XCTest
@testable import Models

final class OpenGraphTests: XCTestCase {
    
    static func makeOpenGraph() -> OpenGraph? {
        
        guard let data = ogJSONString.data(using: .utf8) else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return OpenGraph(from: json)
        
    }
    
    func testInitFromDict () {
        
        let feed = Self.makeOpenGraph()!
        
        XCTAssertEqual(feed.title, "MacStories")
        XCTAssert(feed.url!.absoluteString.contains("macstories"))
        XCTAssertNotNil(feed.summary)
        XCTAssertNotNil(feed.type)
        XCTAssertNotNil(feed.locale)
        XCTAssertNotNil(feed.image)
        
    }
    
    func testDictRepresentation () {
        
        let feed = Self.makeOpenGraph()!
        let dict = feed.dictionaryRepresentation
        
        XCTAssertEqual(feed.title, dict["title"] as? String)
        XCTAssertEqual(feed.url?.absoluteString, dict["url"] as? String)
        XCTAssertEqual(feed.summary, dict["summary"] as? String)
        XCTAssertEqual(feed.type, dict["type"] as? String)
        XCTAssertEqual(feed.locale, dict["locale"] as? String)
        XCTAssertEqual(feed.image?.absoluteString, dict["image"] as? String)
        
    }
    
}

private let ogJSONString = "{\"locale\":\"en_US\",\"type\":\"website\",\"title\":\"MacStories\",\"description\":\"Apple news, app reviews, and stories by Federico Viticci and friends.\",\"url\":\"https://www.macstories.net\",\"image\":\"https://56243e3f6f46fe44a301-deabeb5f3878e3553d0b065ea974f9bf.ssl.cf1.rackcdn.com/256px.png\", \"foo\":\"bar\"}"
