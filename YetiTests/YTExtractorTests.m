//
//  YTExtractorTests.m
//  YetiTests
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YTExtractor.h"

#define waitForExpectation \
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {\
        if(error) NSLog(@"%@", error.localizedDescription);\
    }];

#define videoID @"Bny3yDz05qw"

@interface YTExtractorTests : XCTestCase

@property (nonatomic, strong) YTExtractor * extractor;

@end

@implementation YTExtractorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.extractor = [[YTExtractor alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.extractor = nil;
}

- (void)testExtractInfo {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"YTExtractor:extractInfo"];
    
    [self.extractor extract:videoID success:^(NSURL * _Nonnull videoInfo) {
    
        [expectation fulfill];
        
    } error:^(NSError * _Nonnull error) {
       
        NSLog(@"Error extracting info");
        NSLog(@"Error: %@", error.localizedDescription);
        
    }];
    
    waitForExpectation;
}

- (void)testPerformanceExample {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"YTExtractor:extractInfo"];
    expectation.assertForOverFulfill = NO;
    
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        
        [self.extractor extract:videoID success:^(NSURL * _Nonnull videoInfo) {
            
            [expectation fulfill];
            
        } error:^(NSError * _Nonnull error) {
            
            NSLog(@"Error extracting info");
            NSLog(@"Error: %@", error.localizedDescription);
            
        }];
        
    }];
    
    waitForExpectation;
}

@end
