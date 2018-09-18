//
//  UnreadManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "UnreadManager.h"
#import "YetiConstants.h"

@implementation UnreadManager

- (instancetype)init {
    
    if (self = [super init]) {
        self.feeds = @[];
        self.folders = @[];
    }
    
    return self;
    
}

- (void)finishedUpdating {
    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self];
}

#pragma mark - Getters

- (NSArray <Feed *> *)feedsWithoutFolders {
    return @[];
}

@end
