//
//  User.m
//  Elytra
//
//  Created by Nikhil Nigade on 18/08/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "User.h"

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
        self.subscription = [coder decodeObjectOfClass:Subscription.class forKey:propSel(subscription)];
        
    }
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:self.userID forKey:propSel(userID)];
    
    [coder encodeObject:self.uuid forKey:propSel(uuid)];
    
    [coder encodeObject:self.subscription.dictionaryRepresentation forKey:propSel(subscription)];
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if ([key isEqualToString:propSel(userID)] && value != nil && [value isKindOfClass:NSString.class]) {
        
        value = @([(NSString *)value integerValue]);
        
    }
    
    if ([key isEqualToString:propSel(subscription)] && value != nil && [value isKindOfClass:NSDictionary.class]) {
        
        value = [Subscription instanceFromDictionary:value];
        
    }
    
    [super setValue:value forKey:key];
    
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
    
    return dict;
    
}

@end
