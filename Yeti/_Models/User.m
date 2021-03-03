//
//  User.m
//  Elytra
//
//  Created by Nikhil Nigade on 18/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "User.h"
#import <DZKit/NSArray+RZArrayCandy.h>

@implementation User

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs {
    
    User *instance = [[User alloc] initWithDictionary:attrs];
    
    return instance;
    
}

- (instancetype)initWithDictionary:(NSDictionary *)attrs {
    
    if (self = [super init]) {
        
        self.filters = [NSSet new];
        
        if (attrs && [attrs isKindOfClass:NSDictionary.class]) {
            [self setValuesForKeysWithDictionary:attrs];
        }
    }
    
    return self;
    
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    if (self = [super init]) {
        
        self.userID = [coder decodeObjectOfClass:NSNumber.class forKey:propSel(userID)];
        self.uuid = [coder decodeObjectOfClass:NSString.class forKey:propSel(uuid)];
        self.subscription = [coder decodeObjectOfClass:YTSubscription.class forKey:propSel(subscription)];
        self.filters = [coder decodeObjectOfClasses:[NSSet setWithObjects:NSSet.class, NSString.class, nil] forKey:propSel(filters)];
        
    }
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:self.userID forKey:propSel(userID)];
    
    [coder encodeObject:self.uuid forKey:propSel(uuid)];
    
    [coder encodeObject:self.subscription.dictionaryRepresentation forKey:propSel(subscription)];
    
    [coder encodeObject:self.filters forKey:propSel(filters)];
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if ([key isEqualToString:propSel(userID)] && value != nil && [value isKindOfClass:NSString.class]) {
        
        value = @([(NSString *)value integerValue]);
        
    }
    
    if ([key isEqualToString:propSel(subscription)] && value != nil && [value isKindOfClass:NSDictionary.class]) {
        
        value = [YTSubscription instanceFromDictionary:value];
        
    }
    
    if ([key isEqualToString:propSel(filters)]) {
        
        if (value != nil) {
            
            if ([value isKindOfClass:NSArray.class]) {
                
                value = [value rz_map:^NSString *(NSString * obj, NSUInteger idx, NSArray *array) {
                    return obj.lowercaseString;
                }];
                
                self.filters = [NSSet setWithArray:value];
                
            }
            else if ([value isKindOfClass:NSSet.class]) {
                
                self.filters = value;
                
            }
            else {
                NSLog(@"Unknown value class of type %@ for keyPath:user.filters", NSStringFromClass([value class]));
            }
            
        }
        
    }
    else {
    
        [super setValue:value forKey:key];
        
    }
    
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (NSString *)description {
    return formattedString(@"%@\n%@", [super description], [self dictionaryRepresentation]);
}

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.userID) {
        [dict setObject:self.userID forKey:propSel(userID)];
    }
    
    if (self.uuid) {
        [dict setObject:self.uuid forKey:propSel(uuid)];
    }
    
    if (self.subscription) {
        [dict setObject:self.subscription.dictionaryRepresentation forKey:propSel(subscription)];
    }
    
    if (self.filters) {
        
        [dict setObject:self.filters.allObjects forKey:propSel(filters)];
        
    }
    
    return dict;
    
}

@end
