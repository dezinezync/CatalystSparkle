//
//  Subscription.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Subscription.h"

@implementation Subscription

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs {
    
    Subscription *instance = [[Subscription alloc] initWithDictionary:attrs];
    
    return instance;
    
}

- (instancetype)initWithDictionary:(NSDictionary *)attrs {
    
    if (self = [super init]) {
        if (attrs && [attrs isKindOfClass:NSDictionary.class]) {
            [self setValuesForKeysWithDictionary:attrs];
        }
    }
    
    return self;
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if (([key isEqualToString:@"expiry"] || [key isEqualToString:@"created"]) && [value isKindOfClass:NSString.class]) {
        
        // convert NSString to NSDate
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'zzz'Z'";
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSDate *date = [formatter dateFromString:value];
        
        if (date) {
            [super setValue:date forKey:key];
        }
        
    }
    else if ([key isEqualToString:@"status"]) {
        self.status = [value boolValue];
    }
    else {
        [super setValue:value forKey:key];
    }
    
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    if ([key isEqualToString:@"id"]) {
        self.identifer = value;
    }
    else {
        
    }
}

#pragma mark -

- (BOOL)hasExpired {
    
    if (self.error)
        return YES;
    
    if (self.expiry == nil)
        return YES;
    
    NSDate *now = [NSDate date];
    NSComparisonResult result = [now compare:self.expiry];
    
    return result != NSOrderedAscending;
    
}

@end
