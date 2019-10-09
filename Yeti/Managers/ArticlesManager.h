//
//  ArticlesManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/08/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FeedItem.h"
#import "Folder.h"
#import "Feed.h"

#import "YetiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class ArticlesManager;

@interface ArticlesManager : NSObject

+ (instancetype)shared;

@property (nonatomic, strong) NSArray <Folder *> *folders;

@property (nonatomic, strong) NSArray <Feed *> *feeds;

@property (nonatomic, strong, readonly) NSArray <Feed *> *feedsWithoutFolders;

@property (nonatomic, strong) NSArray <FeedItem *> *bookmarks;

@end

NS_ASSUME_NONNULL_END
