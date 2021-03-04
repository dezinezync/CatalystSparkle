//
//  FolderTests.swift
//  
//
//  Created by Nikhil Nigade on 04/03/21.
//

import XCTest
@testable import Models

final class FolderTests: XCTestCase {
    
    static func makeFolder () -> Folder {
        return Folder(from: [
            "title": "Apps",
            "id": 1,
            "feedIDs": [1, 2, 3, 18]
        ])
    }
    
    func testInitFromDict () {
        
        let folder = Self.makeFolder()
        
        XCTAssertEqual(folder.folderID, 1)
        XCTAssertEqual(folder.title, "Apps")
        XCTAssertEqual(folder.feedIDs.count, 4)
        XCTAssertEqual(folder.unread, 0)
        
    }
    
    func testInitFromDictWithUndefinedKeyPath () {
        
        let folder = Folder(from: [
            "title": "Apps",
            "id": 1,
            "feedIDs": [1, 2, 3, 18],
            "foo": "bar"
        ])
        
        XCTAssertEqual(folder.folderID, 1)
        XCTAssertEqual(folder.title, "Apps")
        XCTAssertEqual(folder.feedIDs.count, 4)
        XCTAssertEqual(folder.unread, 0)
        
    }
    
    func testDictionaryRepresentation () {
        
        let folder = Self.makeFolder()
        let dict = folder.dictionaryRepresentation
        
        XCTAssertEqual(folder.folderID, dict["id"] as? UInt)
        XCTAssertEqual(folder.title, dict["title"] as? String)
        XCTAssertEqual(folder.feedIDs.count, (dict["feedIDs"] as! [UInt]).count)
        XCTAssertEqual(folder.expanded, dict["expanded"] as! Bool)
        
    }

}
