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
    
    var user: User = {
       let u = User()
        u.userID = 7378
        u.uuid = "7EBC0714-2F66-4B8C-BE5B-4014E4ECD04F"
        u.filters = [String]()
        
        return u
    }()
    
    override func setUp() {
        
        super.setUp()
        
        FeedsManager.shared.user = self.user
        
    }
    
    func testGetUser () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.getUser(userID: "000714.d16a484c82844d25ae3016904bcdc9fd.0425") { result in
            
            switch result {
            case .success(let user):
                XCTAssertNotNil(user)
                XCTAssertEqual(user!.userID, 1)
                expectation.fulfill()
            
            case .failure(let error):
                print(error)
            
            }

        }
        
        wait(for: [expectation], timeout: 10)
        
    }
    
    func testStartTrial() {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.startFreeTrial() { result in
            
            switch result {
            case .success(let subscription):
                XCTAssertNotNil(subscription)
                XCTAssert(subscription.hasExpired == false)
                expectation.fulfill()
            
            case .failure(let error):
                print(error)
            
            }

        }
        
        wait(for: [expectation], timeout: 10)
        
    }
    
    func testGetFeeds () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.getFeeds() { result in
            
            switch result {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssert(result.feeds.count > 0)
                XCTAssert(result.folders.count > 0)
                expectation.fulfill()
            
            case .failure(let error):
                print(error)
            
            }

        }
        
        wait(for: [expectation], timeout: 10)
        
    }
    
    static var allTests = [
        ("testGetUser", testGetUser),
    ]
    
}
