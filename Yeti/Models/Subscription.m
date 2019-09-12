//
//  Subscription.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Subscription.h"
#import <DZKit/DZCloudObject.h>
#import "FeedsManager.h"
#import "YetiConstants.h"

@implementation Subscription

+ (BOOL)supportsSecureCoding {
    return YES;
}

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

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.identifer = [decoder decodeObjectForKey:propSel(identifer)];
        self.environment = [decoder decodeObjectForKey:propSel(environment)];
        self.expiry = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:propSel(expiry)]];
        self.created = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:propSel(created)]];
        self.status = [decoder decodeObjectForKey:propSel(status)];
        self.lifetime = [decoder decodeObjectForKey:propSel(lifetime)];
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
    else if ([key isEqualToString:@"preAppstore"]) {
        self.preAppstore = [value boolValue];
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

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.identifer forKey:propSel(identifier)];
    [encoder encodeObject:self.environment forKey:propSel(environment)];
    [encoder encodeDouble:@([self.expiry timeIntervalSince1970]).doubleValue forKey:propSel(expiry)];
    [encoder encodeDouble:@([self.created timeIntervalSince1970]).doubleValue forKey:propSel(created)];
    [encoder encodeBool:self.status forKey:propSel(status)];
    [encoder encodeBool:self.lifetime forKey:propSel(lifetime)];
}

#pragma mark -

- (NSString *)description {
    return formattedString(@"%@\n%@", [super description], [self dictionaryRepresentation]);
}

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.identifer) {
        [dict setValue:self.identifer forKey:propSel(identifer)];
    }
    
    if (self.environment) {
        [dict setValue:self.environment forKey:propSel(environment)];
    }
    
    if (self.identifer) {
        [dict setValue:self.expiry forKey:propSel(expiry)];
    }
    
    if (self.identifer) {
        [dict setValue:self.created forKey:propSel(created)];
    }
    
    if (self.status) {
        [dict setValue:self.status forKey:propSel(status)];
    }
    
    if (self.lifetime) {
        [dict setValue:@(self.lifetime) forKey:propSel(lifetime)];
    }
    
    return dict;
    
}

#pragma mark -

- (BOOL)hasExpired {
    
    if (self.isLifetime) {
        return NO;
    }
    
    if (self.error) {
        
        if ([self.error.localizedDescription isEqualToString:@"No subscription found for this account."]) {
            
            // check if they have added their first feed
            id addedFirst = [MyFeedsManager.keychain stringForKey:YTSubscriptionHasAddedFirstFeed];
            BOOL addedVal = addedFirst ? [addedFirst boolValue] : NO;
            
            // they have added their first feed but haven't purchased a subscription.
            if (addedVal == YES) {
                return YES;
            }
            
            return NO;
        }
        
        return YES;
    }
    
    if (self.expiry == nil)
        return YES;
    
    NSDate *now = [NSDate date];
    NSComparisonResult result = [now compare:self.expiry];
    
    return result != NSOrderedAscending;
    
}

@end
