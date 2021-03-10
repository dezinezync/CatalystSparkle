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
        
        wait(for: [expectation], timeout: 5)
        
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
        
        wait(for: [expectation], timeout: 5)
        
    }
    
    func testGetFeeds () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.getFeeds() { result in
            
            switch result {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssert(result.feeds.count > 0)
                XCTAssert(result.folders.count > 0)
                
                let feed: Feed = result.feeds[0]
                let encoder = JSONEncoder()
                let encoded = try? encoder.encode(feed)
                
                XCTAssertNotNil(encoded)
                
                let decoder = JSONDecoder()
                let decodedFeed: Feed = try! decoder.decode(Feed.self, from: encoded!)
                
                XCTAssertEqual(feed, decodedFeed)
                
                for ck in Feed.CodingKeys.allCases {
                    
                    let key = ck.rawValue
                    
                    let a = feed.value(for: key) as? String
                    let b = decodedFeed.value(for: key) as? String
                    
                    XCTAssertEqual(a, b)
                    
                }
                
                expectation.fulfill()
            
            case .failure(let error):
                print(error)
            
            }

        }
        
        wait(for: [expectation], timeout: 5)
        
    }
    
    func testAddFeedByURL () {
        
        let url = URL(string: "https://blog.elytra.app")!
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.add(feed: url) { (result) in
            
            switch result {
            case .success(let feed):
                XCTAssertEqual(feed.feedID, 18)
                expectation.fulfill()
            case .failure(let error):
                if (error as! FeedsManagerError).message == "Feed already exists in your list." {
                    expectation.fulfill()
                    return
                }
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
        
    }
    
    func testAddFeedByID () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.add(feed: 1, completion: { (result) in
            
            switch result {
            case .success(let feed):
                XCTAssertEqual(feed.feedID, 1)
                expectation.fulfill()
            case .failure(let error):
                if let error = (error as? FeedsManagerError),
                   error.message == "Feed already exists in your list." {
                    expectation.fulfill()
                    return
                }
                print(error)
            }
            
        })
        
        wait(for: [expectation], timeout: 5)
        
    }
    
    func testGetArticlesByFeedID () {
        
        let expectation = XCTestExpectation()
        
        FeedsManager.shared.getArticles(forFeed: 18) { (result) in
            
            switch result {
            case .success(let articles):
                XCTAssertGreaterThan(articles.count, 10)
                expectation.fulfill()
            case .failure(let error):
                print(error)
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
        
    }
    
    static var allTests = [
        ("testGetUser", testGetUser),
    ]
    
}
