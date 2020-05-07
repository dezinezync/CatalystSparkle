//
//  Author.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Author.h"
#import <DZKit/DZLogger.h>

@implementation Author

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs {
    
    Author *instance = [[Author alloc] init];
    
    if (attrs && [attrs isKindOfClass:NSDictionary.class]) {
        [instance setValuesForKeysWithDictionary:attrs];
    }
    
    return instance;
    
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.authorID = [aDecoder decodeObjectOfClass:NSNumber.class forKey:@"authorID"];
        self.name = [aDecoder decodeObjectOfClass:NSString.class forKey:@"name"];
        self.bio = [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[NSString.class, NSArray.class, Content.class]] forKey:@"bio"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.authorID forKey:@"authorID"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.bio forKey:@"bio"];
}

#pragma mark - <NSCopying>

- (instancetype)copy {
    Author *instance = [Author new];
    
    [instance setValuesForKeysWithDictionary:self.dictionaryRepresentation];
    
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark -

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([key isEqualToString:@"bio"]) {
        
        if ([value isKindOfClass:NSString.class]) {
            NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
            value = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        
        if ([value isKindOfClass:NSArray.class]) {
            Content *content = [Content new];
            [content setType:@"container"];
            
            NSMutableArray *members = [NSMutableArray arrayWithCapacity:[(NSArray *)value count]];
            
            for (NSDictionary *item in (NSArray *)value) {
                Content *sub = [Content instanceFromDictionary:item];
                
                [members addObject:sub];
            }
            
            content.items = members;
            
            if (members.count == 1) {
                content = [content.items firstObject];
            }
            
            value = content;
        }
        
        if ([value isKindOfClass:NSDictionary.class]) {
            Content *sub = [Content instanceFromDictionary:value];
            
            value = sub;
        }
        
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    
    if ([key isEqualToString:@"id"]) {
        
        if ([value isKindOfClass:NSString.class]) {
            value = [NSNumber numberWithInteger:[(NSString *)value integerValue]];
        }
        
        self.authorID = value;
    }
    else {
        NSLogDebug(@"Author: Key:%@ - Value:%@", key, value);
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.authorID != nil) {
        [dict setObject:self.authorID forKey:@"authorID"];
    }
    
    if (self.name) {
        [dict setObject:self.name forKey:@"name"];
    }
    
    if (self.bio) {
        if ([self.bio isKindOfClass:Content.class]) {
            [dict setObject:self.bio.dictionaryRepresentation forKey:@"bio"];
        }
        else {
            [dict setObject:self.bio forKey:@"bio"];
        }
    }
    
    return dict.copy;
}

@end
