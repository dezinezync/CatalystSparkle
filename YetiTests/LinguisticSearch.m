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

- (void)testDateForWeeks {
    
    NSString *string = @"1 week ago";
    
    NSDate *date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSTimeInterval days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 7.f, "Expected difference of 7 days");
    
    string = @"A week ago";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 7.f, "Expected difference of 7 days");
    
    string = @"3 weeks ago";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 21.f, "Expected difference of 21 days");
    
    string = @"last week";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 7.f, "Expected difference of 7 days");
    
    string = @"previous week";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 7.f, "Expected difference of 7 days");
    
}

- (void)testDateForTodayAndYesterday {
    
    NSString *string = @"Today";
    
    NSDate *date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSTimeInterval days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 0.f, "Expected difference of 0 days");
    
    string = @"Yesterday";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 1.f, "Expected difference of 1 day");
    
}

- (void)testDateForMonths {
    
    NSString *string = @"1 month ago";
    
    NSDate *date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    NSTimeInterval interval = [date timeIntervalSinceNow];
    NSTimeInterval days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 29.f, "Expected difference of 29 days");
    
    string = @"A month ago";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 29.f, "Expected difference of 29 days");
    
    string = @"3 months ago";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 87.f, "Expected difference of 87 days");
    
    string = @"last month";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 29.f, "Expected difference of 29days");
    
    string = @"previous month";
    
    date = [LinguisticSearch dateFromText:string];
    
    XCTAssert(date != nil, @"Date was nil");
    
    interval = [date timeIntervalSinceNow];
    days = floor(fabs(interval / 86400));
    
    XCTAssert(days == 29.f, "Expected difference of 29 days");
    
}

- (void)testTimePeriodsFor1Month {
    
    NSString *text = @"1 month";
    
    NSArray <NSDate *> *dates = [LinguisticSearch timePeriodFromText:text];
    
    XCTAssert(dates != nil, @"Dates were nil");
    
    NSTimeInterval interval = [dates.lastObject timeIntervalSinceDate:dates.firstObject];
    NSTimeInterval days = floor(fabs(interval / 86400.f));
    
    XCTAssert(days == 29.f, @"Expected difference to be 29 days");
    
}

- (void)testTimePeriodsFor2Months {
    
    NSString *text = @"2 months";
    
    NSArray <NSDate *> *dates = [LinguisticSearch timePeriodFromText:text];
    
    XCTAssert(dates != nil, @"Dates were nil");
    
    NSTimeInterval interval = [dates.lastObject timeIntervalSinceDate:dates.firstObject];
    NSTimeInterval days = floor(fabs(interval / 86400.f));
    
    XCTAssert(days == (29.f * 2), @"Expected difference to be 58 days");
    
}

- (void)testTimePeriodsForLastWeek {
    
    NSString *text = @"last week";
    
    NSArray <NSDate *> *dates = [LinguisticSearch timePeriodFromText:text];
    
    XCTAssert(dates != nil, @"Dates were nil");
    
    NSTimeInterval interval = [dates.lastObject timeIntervalSinceDate:dates.firstObject];
    NSTimeInterval days = floor(fabs(interval / 86400.f));
    
    XCTAssert(days == 7, @"Expected difference to be 7 days");
    
}

@end
