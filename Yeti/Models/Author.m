//
//  Author.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Author.h"

@implementation Author

+ (instancetype)instanceFromDictionary:(NSDictionary *)attrs {
    
    Author *instance = [[Author alloc] init];
    
    if (attrs && [attrs isKindOfClass:NSDictionary.class]) {
        [instance setValuesForKeysWithDictionary:attrs];
    }
    
    return instance;
    
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
        DDLogDebug(@"Author: Key:%@ - Value:%@", key, value);
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.authorID) {
        [dict setObject:self.authorID forKey:@"authorID"];
    }
    
    if (self.name) {
        [dict setObject:self.name forKey:@"name"];
    }
    
    if (self.bio) {
        [dict setObject:self.bio forKey:@"bio"];
    }
    
    return dict.copy;
}

@end
