//
//  UnreadManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Feed.h"
#import "Folder.h"

NS_ASSUME_NONNULL_BEGIN

@interface UnreadManager : NSObject

@property (nonatomic, strong) NSArray <Feed *> * feeds;
@property (nonatomic, strong) NSArray <Folder *> * folders;

@property (nonatomic, readonly) NSArray <Feed *> *feedsWithoutFolders;

// dispatches relevant notifications after the above sources have been updated.
- (void)finishedUpdating;

@end

NS_ASSUME_NONNULL_END
