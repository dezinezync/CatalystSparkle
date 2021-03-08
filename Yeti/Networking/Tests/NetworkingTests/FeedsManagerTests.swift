//
//  FeedsManagerTests.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import XCTest
import Models
@testable import Networking

final class FeedsManagerTests: XCTestCase {
    
    func testGetUser () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.getUser(uuid: "000714.d16a484c82844d25ae3016904bcdc9fd.0425") { (user) in
            
            XCTAssertNotNil(user)
            expectation.fulfill()
            
        } failure: { (error) in
            print(error)
        }

        
        wait(for: [expectation], timeout: 10)
        
    }
    
    static var allTests = [
        ("testGetUser", testGetUser),
    ]
    
}
