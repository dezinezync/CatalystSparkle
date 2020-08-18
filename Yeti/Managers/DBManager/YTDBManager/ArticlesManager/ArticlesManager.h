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

#import <DZTextKit/YetiConstants.h>

NS_ASSUME_NONNULL_BEGIN

@class ArticlesManager;

@interface ArticlesManager : NSObject <UIStateRestoring, UIObjectRestoration, NSCoding, NSSecureCoding>

@property (class, nonatomic, nonnull) ArticlesManager * shared;

@property (nonatomic, strong) NSArray <Folder *> * _Nullable folders;

- (Folder * _Nullable)folderForID:(NSNumber * _Nonnull)folderID;

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

- (Feed * _Nullable)feedForID:(NSNumber * _Nonnull)feedID;

@property (nonatomic, strong, readonly) NSArray <Feed *> * _Nullable feedsWithoutFolders;

@property (nonatomic, strong) NSArray <FeedItem *> * _Nullable bookmarks;

- (void)willBeginUpdatingStore;

- (void)didFinishUpdatingStore;

@end

NS_ASSUME_NONNULL_END
