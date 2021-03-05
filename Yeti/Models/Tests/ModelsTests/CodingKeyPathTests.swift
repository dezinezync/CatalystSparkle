//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import XCTest
@testable import Models

final class CodingKeyPathTests: XCTestCase {
    
    func testHasKey () {
        
        let user = User()
        user.userID = 1
        
        XCTAssertEqual(user.hasKey(for: "userID"), true)
        XCTAssertEqual(user.hasKey(for: "id"), false)
        
    }
    
    func testValueFor () {
        
        let user = User()
        user.userID = 1
        
        XCTAssertEqual(user.value(for: "userID") as? UInt, 1)
        XCTAssertNil(user.value(for: "id"))
        
    }
    
}
