//
//  UserTests.m
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import XCTest
@testable import Models

final class UserTests: XCTestCase {
    
    static func makeUser () -> User {
        return User(from: [
            "uuid": "000714.d16a484c82844d25ae3016904bcdc9fd.0425",
            "userID": 1,
            "filters": ["sponsor", "sponsored", "sponsoring", "comicon", "corona"],
            "expiry": Date().addingTimeInterval(86400)
        ])
    }
    
    func testInitFromDict () {
        
        let user = User(from: [
            "uuid": "000714.d16a484c82844d25ae3016904bcdc9fd.0425",
            "id": 1,
            "filters": ["sponsor", "sponsored", "sponsoring", "comicon", "corona"]
        ])
        
        XCTAssertEqual(user.uuid, "000714.d16a484c82844d25ae3016904bcdc9fd.0425")
        XCTAssertEqual(user.userID, 1)
        XCTAssertEqual(user.filters.count, 5)
        XCTAssert(user.filters.contains("comicon"))
        
    }
    
    func testInitFromDictWithNSNumber () {
        
        let user = User(from: [
            "uuid": "000714.d16a484c82844d25ae3016904bcdc9fd.0425",
            "id": NSNumber(integerLiteral: 1),
            "filters": ["sponsor", "sponsored", "sponsoring", "comicon", "corona"]
        ])
        
        XCTAssertEqual(user.uuid, "000714.d16a484c82844d25ae3016904bcdc9fd.0425")
        XCTAssertEqual(user.userID, 1)
        XCTAssertEqual(user.filters.count, 5)
        XCTAssert(user.filters.contains("comicon"))
        
    }
    
    func testInitFromDictWithSet () {
        
        let user = User(from: [
            "uuid": "000714.d16a484c82844d25ae3016904bcdc9fd.0425",
            "id": NSNumber(integerLiteral: 1),
            "filters": Set<String>(["sponsor", "sponsored", "sponsoring", "comicon", "corona"])
        ])
        
        XCTAssertEqual(user.uuid, "000714.d16a484c82844d25ae3016904bcdc9fd.0425")
        XCTAssertEqual(user.userID, 1)
        XCTAssertEqual(user.filters.count, 5)
        XCTAssert(user.filters.contains("comicon"))
        
    }
    
    func testDictionaryRepresentation () {
        
        let user = UserTests.makeUser()
        user.setValue(subJSON, forKey: "subscription")
        
        let dict = user.dictionaryRepresentation
        
        XCTAssertEqual(dict.keys.count, 4)
        
        XCTAssertEqual(dict["uuid"] as! String, "000714.d16a484c82844d25ae3016904bcdc9fd.0425")
        XCTAssertEqual(dict["userID"] as! UInt, 1)
        XCTAssertEqual((dict["filters"] as! [String]).count, 5)
        XCTAssert((dict["filters"] as! [String]).contains("comicon"))
        XCTAssertNotNil(dict["subscription"])
        
    }
    
    func testDescription () {
        
        let user = UserTests.makeUser()
        
        let description = user.description
        
        XCTAssert(description.contains("sponsoring"))
        
    }
    
    func testCopy () {
        
        let user = UserTests.makeUser()
        
        let copy = user.copy() as User
        
        XCTAssertEqual(user.userID, copy.userID)
        XCTAssertEqual(user.uuid, copy.uuid)
        XCTAssertEqual(user.filters, copy.filters)
        
    }
    
    func testSettingSub () {
        
        var user = Self.makeUser()
        
        user.setValue(subJSON, forKey: "subscription")
        
        user.subscription.setValue("2025-12-31T00:00:00.000Z", forKey: "expiry")
        
        XCTAssertNotNil(user.subscription)
        XCTAssertEqual(user.subscription.status, .active)
        
    }

}

private let subJSON = "{\"lifetime\":false,\"preAppStore\":false,\"created\":\"2018-06-01T00:00:00.000Z\",\"external\":false,\"environment\":\"Production\",\"id\":1,\"expiry\":\"2021-03-04T19:44:03.000Z\",\"status\":1}"

