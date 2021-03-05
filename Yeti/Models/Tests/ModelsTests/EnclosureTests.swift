//
//  EnclosureTests.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
@testable import Models

final class EnclosureTests: XCTestCase {
    
    func testInitFromDict() {
        
        let enclosure = Enclosure(from:[
            "length": 123456789,
            "type": "image/png",
            "url": "https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png"
        ])
        
        XCTAssertEqual(enclosure.length, 123456789)
        XCTAssertEqual(enclosure.type, "image/png")
        XCTAssertEqual(enclosure.url.absoluteString, "https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png")
        
    }
    
    func testInitFromDictWithURL() {
        
        let enclosure = Enclosure(from:[
            "length": 123456789,
            "type": "image/png",
            "url": URL(string:"https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png")!
        ])
        
        XCTAssertEqual(enclosure.length, 123456789)
        XCTAssertEqual(enclosure.type, "image/png")
        XCTAssertEqual(enclosure.url.absoluteString, "https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png")
        
    }
    
    func testDictRepresentation() {
        
        let enclosure = Enclosure(from:[
            "length": 123456789,
            "type": "image/png",
            "url": "https://blog.elytra.app/wp-content/uploads/2021/01/elytra-v2.2@2x.png"
        ])
        
        let dict = enclosure.dictionaryRepresentation
        
        XCTAssertEqual(enclosure.length, dict["length"] as? Double)
        XCTAssertEqual(enclosure.type, dict["type"] as? String)
        XCTAssertEqual(enclosure.url.absoluteString, dict["url"] as? String)
        
    }
    
}
