//
//  MetaData.m
//  YetiTests
//
//  Created by Nikhil Nigade on 22/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FeedMeta.h"

#import <LinkPresentation/LinkPresentation.h>

@interface MetaData : XCTestCase {
    NSURL *_url;
}

@end

@implementation MetaData

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _url = [NSURL URLWithString:@"https://macstories.net"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Fetch LPLinkMetadata for url"];
    
    LPMetadataProvider *provider = [LPMetadataProvider new];
    
    [provider startFetchingMetadataForURL:_url completionHandler:^(LPLinkMetadata * _Nullable metadata, NSError * _Nullable error) {
        
        FeedMeta *meta = [FeedMeta new];
        
        @try {
            if ([metadata valueForKeyPath:@"icons"] != nil) {
                
                NSArray *icons = [metadata valueForKeyPath:@"icons"];
                
                if (icons.count > 0) {
                    NSMutableDictionary *iconsDict = @{}.mutableCopy;
                    
                    for (id icon in icons) {
                        NSString *iconURL = [[icon valueForKeyPath:@"URL"] absoluteString];
                        
                        NSString *lastComp = [iconURL lastPathComponent];
                        
                        NSLog(@"LastComp: %@", lastComp);
                        
                        iconsDict[lastComp] = iconURL;
                    }
                    
                    meta.icons = iconsDict;
                }
            }
            
            
            {
                meta.icon = [metadata valueForKeyPath:@"_iconMetadata._URL"];
            }
            
            if (meta.icon && meta.icon.class == NSURL.class) {
                meta.icon = ((NSURL *)(meta.icon)).absoluteString;
            }
        } @catch (NSException *exception) {
            NSLog(@"Exception: %@", exception);
        }
        @finally {}
        
        meta.title = metadata.title;
        meta.url = metadata.URL.absoluteString;
        meta.summary = [metadata valueForKeyPath:@"summary"];
        
        MetaOpenGraph *graph = [MetaOpenGraph new];
        
        NSLog(@"Metadata: %@", metadata);
        
        [expectation fulfill];
        
    }];
    
    [self waitForExpectations:@[expectation] timeout:10];
    
}

@end
