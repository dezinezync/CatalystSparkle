//
//  ContentRangeTests.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
@testable import Models

final class ContentRangeTests: XCTestCase {
    
    func testInitFromDict() {
        
        let range = ContentRange(from: [
            "element": "link",
            "range": "25,5",
            "type": "link",
            "url": "https://elytra.app/"
        ])
        
        XCTAssertEqual(range.element, "link")
        XCTAssertEqual(range.range?.location, 25)
        XCTAssertEqual(range.range?.length, 5)
        XCTAssertEqual(range.type, "link")
        XCTAssertEqual(range.url?.absoluteString, "https://elytra.app/")
        
    }
    
    func testDictRepresentation() {
        
        let range = ContentRange(from: [
            "element": "link",
            "range": "25,5",
            "type": "link",
            "url": "https://elytra.app/",
            "level": 0
        ])
        
        let dict = range.dictionaryRepresentation
        
        for name in ContentRange.CodingKeys.allCases {
            
            let key = name.rawValue
            
            if key == "range" {
                XCTAssertEqual(NSStringFromRange(range.range!), dict["range"] as? String)
            }
            else {
                XCTAssertEqual(range.value(for: key) as? AnyHashable, dict[key] as? AnyHashable)
            }
            
        }
        
    }
    
    func testInitForURL() {
        
        let range = ContentRange(from: [
            "element": "link",
            "url": URL(string: "https://elytra.app/")!,
            "range": "25,5"
        ])
        
        XCTAssertEqual(range.element, "link")
        XCTAssertEqual(range.url?.absoluteString, "https://elytra.app/")
        
    }
    
    func testInitForRange() {
        
        let range = ContentRange(from: [
            "element": "link",
            "url": URL(string: "https://elytra.app/")!,
            "range": NSRange(location: 25, length: 5)
        ])
        
        XCTAssertEqual(range.range?.location, 25)
        XCTAssertEqual(range.range?.length, 5)
        
        let dict = range.dictionaryRepresentation
        
        XCTAssertEqual(dict["range"] as? String, "{25, 5}")
        
    }
    
}
