//
//  LinguisticSearch.m
//  YetiTests
//
//  Created by Nikhil Nigade on 15/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LinguisticSearch.h"

@interface LinguisticSearchTests : XCTestCase {}

@end

@implementation LinguisticSearchTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDateYesterday {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"Yesterday at 1:30AM";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    
    XCTAssert(dateNouns.count == 1, @"expected only 1 date noun");
}

- (void)testDateToday {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"Today at 1:30AM";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    
    XCTAssert(dateNouns.count == 1, @"expected only 1 date noun");
}

- (void)testDateYesterdayLowercase {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"yesterday at 1:30AM";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    
    XCTAssert(dateNouns.count == 1, @"expected only 1 date noun");
}

- (void)testDateTodayLowercase {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"today at 1:30AM";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    
    XCTAssert(dateNouns.count == 1, @"expected only 1 date noun");
}

- (void)testLastWeek {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"last week";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    NSArray *contexts = [results valueForKey:LinguisticPairTypeContext];
    
    XCTAssert(dateNouns.count == 1 && contexts.count == 1, @"expected only 1 date noun");
}

- (void)testOneWeekAgo {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"1 week ago";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    NSArray *contexts = [results valueForKey:LinguisticPairTypeContext];
    
    XCTAssert(dateNouns.count == 1 && contexts.count == 1, @"expected only 1 date noun");
}

- (void)testAWeekAgo {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSString *string = @"a week ago";
    NSDictionary <LinguisticPairType, NSArray <LinguisticTagPair> *> *results = [LinguisticSearch processText:string];
    
    NSArray *dateNouns = [results valueForKey:LinguisticPairTypeDates];
    NSArray *contexts = [results valueForKey:LinguisticPairTypeContext];
    
    XCTAssert(dateNouns.count == 1 && contexts.count == 1, @"expected only 1 date noun");
}

@end
