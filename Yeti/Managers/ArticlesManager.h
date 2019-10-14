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

@interface ArticlesManager : NSObject <UIStateRestoring, UIObjectRestoration, NSCoding, NSSecureCoding>

@property (class, nonatomic, nonnull) ArticlesManager * shared;

@property (nonatomic, strong) NSArray <Folder *> * _Nullable folders;

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

@property (nonatomic, strong, readonly) NSArray <Feed *> * _Nullable feedsWithoutFolders;

@property (nonatomic, strong) NSArray <FeedItem *> * _Nullable bookmarks;

@end

NS_ASSUME_NONNULL_END
