//
//  NSString+ImageProxy.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NSString+ImageProxy.h"
#import "YetiConstants.h"

@implementation NSString (ImageProxy)

- (NSString *)pathForImageProxy:(BOOL)usedSRCSet maxWidth:(CGFloat)maxWidth quality:(CGFloat)quality {
    
    NSString *copy = [self copy];
    
    maxWidth = maxWidth ?: [UIScreen mainScreen].bounds.size.width;
    
    NSSet *const knownProxies = [NSSet setWithObjects:@"9to5mac.com", nil];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:copy];
    
    if (components.host != nil && [knownProxies containsObject:components.host]) {
        // these are known proxies.
        // but we also need to know if the width element is present
        NSRange widthPointer = [components.query rangeOfString:@"w="];
        
        if (widthPointer.location != NSNotFound) {
            NSRange inRange = NSMakeRange(widthPointer.location, components.query.length - widthPointer.location);
            NSRange widthEndPointer = [components.query rangeOfString:@"&" options:kNilOptions range:inRange];
            
            NSString *queryString = components.query;
            
            if (widthEndPointer.location == NSNotFound) {
                // end of the query string
                NSInteger from = widthPointer.location + widthPointer.length;
                
                queryString = [queryString stringByReplacingCharactersInRange:NSMakeRange(from, components.query.length - from) withString:@(maxWidth).stringValue];
            }
            else {
                widthPointer.location = widthPointer.location + widthPointer.length;
                widthPointer.length = widthEndPointer.location - widthPointer.location;
                
                queryString = [queryString stringByReplacingCharactersInRange:widthPointer withString:@(maxWidth).stringValue];
            }
            
            components.query = queryString;
        }
        else {
            components.query = [(components.query ?: @"") stringByAppendingFormat:@"&w=%@", @(maxWidth).stringValue];
        }
        
        copy = [[components URL] absoluteString];
        
        return copy;
    }
    
    NSString *sizePreference = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsImageLoading];
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:kUseImageProxy]) {
        
        if (fabs(quality) <= 0) {
            
            if (usedSRCSet == YES) {
                quality = 100;
            }
            else {
                NSInteger quality = 90;
                
                if ([sizePreference isEqualToString:ImageLoadingLowRes]) {
                    quality = 60;
                }
                else if ([sizePreference isEqualToString:ImageLoadingMediumRes]) {
                    quality = 75;
                }
            }
            
        }
        
        copy = formattedString(@"https://images.weserv.nl/?url=%@", copy);
        
        if (usedSRCSet == NO) {
            copy = formattedString(@"%@&w=%@&dpr=%@&output=jpeg&q=%@", copy, @(maxWidth), @(UIScreen.mainScreen.scale), @(quality));
        }
        
//        DDLogInfo(@"weserv.nl proxy URL: %@", copy);
        
    }
    
    return copy;
    
}

@end
