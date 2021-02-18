import XCTest
@testable import FeedsLib

final class FeedsLibTests: XCTestCase {
    
    func testRecommendations() {
        
        let expectation = self.expectation(description: "getRecommendations")
        
        FeedsLib.shared.getRecommendations(topic: "tech", locale: "en") { (error: Error?, response: RecommendationsResponse?) in
            
            XCTAssert(error == nil, "Got an error: \(error?.localizedDescription ?? "No error description")")
            
            guard let response = response else {
                return
            }
            
            XCTAssert(response.topic == "tech", "Expected topic to be the same as in the request")
            XCTAssert(response.feedInfos?.count ?? 0 > 0, "Expected atleast one feed in the list")
            
            guard let result = response.feedInfos?[0] else {
                return
            }
            
            XCTAssert(result.website?.contains("verge") == true, "Expected first result to be verge.com")
            
            expectation.fulfill()
            
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
    }
    
    func testFeedInfo() {
        
        guard let url = URL(string: "https://dezinezync.com/") else {
            return
        }
        
        let expectation = self.expectation(description: "getFeedInfo")
        
        FeedsLib.shared.getFeedInfo(url: url) { (error: Error?, data: FeedInfoResponse?) in
            
            XCTAssert(error == nil, "Got an error: \(error?.localizedDescription ?? "No error description")")
            
            guard let data = data else {
                XCTAssert(true == false, "Expected data in response when no error is present")
                return
            }
            
            guard let results = data.results else {
                XCTAssert(true == false, "Expected results key in response.")
                return
            }
            
            XCTAssert(results.count > 2, "Expected atleast 3 items in the results.")
            
            let result = results[0]
            
            guard let id = result.id, id == "feed/https://dezinezync.com/feed.json" else {
                XCTAssert(true == false, "Expected first id to be feed.json URL")
                return
            }
            
            guard let title = result.title, title == "Nikhil Nigade" else {
                XCTAssert(true == false, "Expected first url to be Nikhil Nigade")
                return
            }
            
            guard let iconURL = result.iconUrl, iconURL.contains("dezinezync/") == true else {
                XCTAssert(true == false, "Expected iconUrl to include username")
                return
            }
            
            expectation.fulfill()
            
        }
        
        waitForExpectations(timeout: 10, handler: nil)
        
    }

    static var allTests = [
        ("testRecommendations", testRecommendations),
        ("testFeedInfo", testFeedInfo)
    ]
}
