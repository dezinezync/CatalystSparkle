//
//  SyncChange.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SyncChange.h"

@implementation SyncChange

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
    if ([key isEqualToString:@"id"]
        || [key isEqualToString:@"userID"]
        || [key isEqualToString:@"created"]
        || [key isEqualToString:@"modified"]) {
        // ignore these keys
    }
    else {
        [super setValue:value forUndefinedKey:key];
    }
    
}

@end
