//
//  DZLoggingJSONResponseParser.m
//  Elytra
//
//  Created by Nikhil Nigade on 11/01/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import "DZLoggingJSONResponseParser.h"

@implementation DZLoggingJSONResponseParser

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error {
    
    __autoreleasing id responseObject = [super parseResponse:responseData :response error:error];
    
    if (responseObject != nil && MyFeedsManager.debugLoggingEnabled) {
        
        CWLogData(@{@"url": response.URL.absoluteString,
                    @"headers": response.allHeaderFields,
                    @"response": responseObject
                  });
        
    }
    
    return responseObject;
    
}

@end
