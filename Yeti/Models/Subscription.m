//
//  Subscription.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Subscription.h"
#import "Keychain.h"

@implementation YTSubscription

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs {
    
    YTSubscription *instance = [[YTSubscription alloc] initWithDictionary:attrs];
    
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
        self.identifer = [decoder decodeObjectOfClass:NSNumber.class forKey:propSel(identifer)];
        self.environment = [decoder  decodeObjectOfClass:NSString.class forKey:propSel(environment)];
        self.expiry = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:propSel(expiry)]];
        self.created = [NSDate dateWithTimeIntervalSince1970:[decoder decodeDoubleForKey:propSel(created)]];
        self.status = [decoder  decodeObjectOfClass:NSNumber.class  forKey:propSel(status)];
        self.lifetime = [decoder decodeBoolForKey:@"lifetime"];
        self.external = [decoder decodeBoolForKey:@"external"];
    }
    
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if (([key isEqualToString:@"expiry"] || [key isEqualToString:@"created"]) && [value isKindOfClass:NSString.class]) {
        
        if ([value containsString:@".000Z"]) {
            
            value = [(NSString *)value stringByReplacingOccurrencesOfString:@".000Z" withString:@".GMTZ"];
        }
        
        // convert NSString to NSDate
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'zzz'Z'";
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSDate *date = [formatter dateFromString:value];
        
        if (date) {
            [super setValue:date forKey:key];
        }
        
        if ([key isEqualToString:@"expiry"] && self.external == NO) {
            
            NSInteger era, year, month, day;
            
            [NSCalendar.currentCalendar getEra:&era year:&year month:&month day:&day fromDate:date];
            
            if (year == 2025 && month == 12 && day == 31) {
                self.lifetime = YES;
            }
            
        }
        
    }
    else if ([key isEqualToString:@"expiry"]
             && value != nil
             && [value isKindOfClass:NSDate.class]
             && self.external == NO) {
        
        NSInteger era, year, month, day;
        
        [NSCalendar.currentCalendar getEra:&era year:&year month:&month day:&day fromDate:value];
        
        if (year == 2025 && month == 12 && day == 31) {
            self.lifetime = YES;
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
    else if ([key isEqualToString:@"stripe"] && value != nil) {
        
        if ([value isKindOfClass:NSString.class]) {
            
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            
            NSArray <NSDictionary *> *items = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            if (items != nil) {
                
                NSDictionary *latest = nil;
                
                if ([items isKindOfClass:NSArray.class]) {
                    
                    NSSortDescriptor *sortByPeriodEnd = [NSSortDescriptor sortDescriptorWithKey:@"current_period_end" ascending:YES];
                    
                    items = [items sortedArrayUsingDescriptors:@[sortByPeriodEnd]];
                    
                    latest = [items lastObject];
                    
                }
                else if ([items isKindOfClass:NSDictionary.class]) {
                    latest = (id)items;
                }
                else {
                    return;
                }
                
                NSTimeInterval ending = [[latest valueForKey:@"current_period_end"] doubleValue];
                
                NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:ending];
                
                NSTimeInterval timeSinceNow = [endDate timeIntervalSinceNow];
                
                self.external = YES;
                self.expiry = endDate;
                
                self.expired = (timeSinceNow < 0);
                
            }
            
        }
        
    }
    else {
        
    }
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.identifer forKey:propSel(identifier)];
    [encoder encodeObject:self.environment forKey:propSel(environment)];
    [encoder encodeDouble:@([self.expiry timeIntervalSince1970]).doubleValue forKey:propSel(expiry)];
    [encoder encodeDouble:@([self.created timeIntervalSince1970]).doubleValue forKey:propSel(created)];
    [encoder encodeBool:self.status.boolValue forKey:propSel(status)];
    [encoder encodeBool:self.lifetime forKey:propSel(lifetime)];
    [encoder encodeBool:self.external forKey:propSel(external)];
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
    
    [dict setValue:@(self.lifetime) forKey:propSel(lifetime)];
    
    [dict setValue:@(self.external) forKey:propSel(external)];
    
    if (self.expiry) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'zzz'Z'";
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        [dict setValue:[formatter stringFromDate:self.expiry] forKey:propSel(expiry)];
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
            id addedFirst = [Keychain stringFor:@"com.dezinezync.elytra.pro.hasAddedFirstFeed" error:nil];
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
