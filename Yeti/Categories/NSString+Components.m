//
//  NSString+Components.m
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NSString+Components.h"

@implementation NSString (Components)

- (NSDictionary *)queryComponents {
    
    NSMutableDictionary *components = @{}.mutableCopy;
    
    NSArray <NSString *> *baseComponents = [self componentsSeparatedByString:@"&"];
    
    for (NSString *string in baseComponents) {
        
        NSArray <NSString *> *compounded = [string componentsSeparatedByString:@"="];
        
        if ([compounded count] == 2) {
            NSString *key = [[compounded firstObject] decode];
            NSString *value = [[compounded lastObject] decode];
            
            if (value && [value length]) {
                components[key] = value;
            }
        }
        
    }
    
    return components.copy;
    
}

- (NSString *)decode {
    return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
}

@end
