//
//  NSString+ImageProxy.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NSString+ImageProxy.h"

@implementation NSString (ImageProxy)

- (NSString *)pathForImageProxy:(BOOL)usedSRCSet
                       maxWidth:(CGFloat)maxWidth
                        quality:(CGFloat)quality {
    
    return [self pathForImageProxy:usedSRCSet maxWidth:maxWidth quality:quality firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
    
}

- (NSString *)pathForImageProxy:(BOOL)usedSRCSet
                       maxWidth:(CGFloat)maxWidth
                        quality:(CGFloat)quality
               firstFrameForGIF:(BOOL)firstFrameForGIF
                  useImageProxy:(BOOL) useImageProxy
                   sizePreference:(ImageLoadingOption)sizePreference {
    
    NSString *copy = [self copy];
    
    if ([copy containsString:@".gif"] && firstFrameForGIF == NO) {
        /*
         * weserv.nl does not support gifs properly as of 29/03/2020.
         * It returns the first frame from the GIF.
         * So we do not use it to proxy images.
         * We do however use it to fetch the first frame of the gif.
         */
        return copy;
    }
    
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
    
    
    if (useImageProxy) {
        
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
        
        copy = formattedString(@"https://images.weserv.nl/?url=%@", [copy stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]);
        
        CGFloat scale = UIScreen.mainScreen.scale;
        
//        if (usedSRCSet == NO) {
            
            NSString *extension = [self pathExtension] ?: @"jpeg";
        
        NSString *name = [[self lastPathComponent] stringByReplacingOccurrencesOfString:extension withString:@""];
        
            maxWidth = maxWidth/scale;
        
        maxWidth += 200.f;
            
            copy = formattedString(@"%@&w=%@&dpr=%@&output=%@&q=%@&filename=%@@%@x.%@&we", copy, @(maxWidth), @(UIScreen.mainScreen.scale), extension, @(quality), name, @(scale), extension);
//        }
        
//        NSLog(@"weserv.nl proxy URL: %@", copy);
        
    }
    
    return copy;
    
}

@end
