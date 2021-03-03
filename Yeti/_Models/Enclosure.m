//
//  Enclosure.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/10/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import "Enclosure.h"

@implementation Enclosure

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (NSString *)compareID
{
    return self.url.absoluteString;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.length forKey:@"length"];
    [encoder encodeObject:self.type forKey:@"type"];
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.cmtime forKey:@"cmtime"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder])) {
        self.length = [decoder decodeObjectOfClass:NSNumber.class forKey:@"length"];
        self.type = [decoder decodeObjectOfClass:NSString.class forKey:@"type"];
        self.url = [decoder decodeObjectOfClass:NSURL.class forKey:@"url"];
        self.cmtime = [decoder decodeObjectOfClass:NSValue.class forKey:@"cmtime"];
    }
    return self;
}

+ (Enclosure *)instanceFromDictionary:(NSDictionary *)aDictionary
{

    Enclosure *instance = [[Enclosure alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;

}

- (void)setAttributesFromDictionary:(NSDictionary *)aDictionary
{

    if (![aDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }

    [self setValuesForKeysWithDictionary:aDictionary];

}

- (void)setValue:(id)value forKey:(NSString *)key
{
    
    if ([value isKindOfClass:NSDate.class]) {
        
    }
    
    if ([key isEqualToString:@"url"]) {
        if ([value isKindOfClass:NSString.class])
            value = [NSURL URLWithString:value];
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"created"] || [key isEqualToString:@"modified"] || [key isEqualToString:@"articleID"]) {}
    else
        NSLog(@"Wanring: %@ : %@-%@", NSStringFromClass(self.class), key, value);
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.length != nil) {
        [dictionary setObject:self.length forKey:@"length"];
    }

    if (self.type) {
        [dictionary setObject:self.type forKey:@"type"];
    }

    if (self.url) {
        
        if ([self.url isKindOfClass:NSURL.class]) {
            [dictionary setObject:self.url.absoluteString forKey:@"url"];
        }
        else {
            [dictionary setObject:self.url forKey:@"url"];
        }
        
    }
    
    if (self.cmtime) {
        [dictionary setObject:self.cmtime forKey:@"cmtime"];
    }

    return dictionary;

}

@end
