//
//  NSString+CJK.m
//  Elytra
//
//  Created by Nikhil Nigade on 11/10/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "NSString+CJK.h"
#import <objc/runtime.h>

static void *NSStringCJKRegExp;

@implementation NSString (CJK)

- (BOOL)containsCJKCharacters {
    
    if (![self length])
        return NO;
        
    NSRegularExpression *regex = [self CJKRegExp];
    
    return ([regex matchesInString:self options:0 range:NSMakeRange(0, [self length])]).count > 0;
    
}

- (NSRegularExpression *)CJKRegExp {
    
  NSRegularExpression *result = objc_getAssociatedObject(self, &NSStringCJKRegExp);
    
    if (result == nil) {

      result = [NSRegularExpression regularExpressionWithPattern:@"[\\u2E80-\\u9FFF]" options:NSRegularExpressionCaseInsensitive error:nil];
      
      objc_setAssociatedObject(self, &NSStringCJKRegExp, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      
    }
    
    return result;
}

@end
