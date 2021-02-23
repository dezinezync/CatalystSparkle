//
//  ArticlesManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/08/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticlesManager.h"
#import <DZkit/NSArray+RZArrayCandy.h>
#import "DBManager+Spotlight.h"

static ArticlesManager * SharedArticleManager = nil;

@interface ArticlesManager () {
    BOOL _updatingStores;
}

@property (nonatomic, strong, readwrite) NSArray <Feed *> * _Nullable feedsWithoutFolders;

@end

@implementation ArticlesManager

+ (BOOL)supportsSecureCoding {
    return YES;
}

+ (instancetype)shared {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedArticleManager = [ArticlesManager new];
    });
    
    return SharedArticleManager;
    
}

+ (void)setShared:(ArticlesManager *)shared {
    
    SharedArticleManager = shared;
    
}

- (instancetype)init {
    
    if (self = [super init]) {
        _feeds = @[];
        _folders = @[];
        _feedsWithoutFolders = @[];
    }
    
    return self;
    
}

- (void)willBeginUpdatingStore {
    
    if (_updatingStores == YES) {
        return;
    }
    
    _updatingStores = YES;
    
}

- (void)didFinishUpdatingStore {
    
    [self didFinishUpdatingStore:YES];
    
}

- (void)didFinishUpdatingStore:(BOOL)notify {
    
    if (_updatingStores == NO) {
        return;
    }
    
    _updatingStores = NO;
    
    if (notify) {
        
        self.feedsWithoutFolders = nil;
        
        [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self userInfo:nil];
        
    }
    
}

#pragma mark - Getters

- (NSArray <Feed *> *)feedsWithoutFolders {
    
    if (_feedsWithoutFolders == nil) {
        
        NSArray <Feed *> * feeds = [self.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
            return obj.folderID == nil;
        }];
        
        _feedsWithoutFolders = feeds;
        
    }
    
    return _feedsWithoutFolders;
        
}

- (Folder *)folderForID:(NSNumber *)folderID {
    
    Folder *folder = [self.folders rz_find:^BOOL(Folder *obj, NSUInteger idx, NSArray *array) {
       
        return obj.folderID.integerValue == folderID.integerValue;
        
    }];
    
    return folder;
    
}

- (Feed *)feedForID:(NSNumber *)feedID {
    
    if (feedID == nil) {
        return nil;
    }
    
    Feed * filtered = [ArticlesManager.shared.feeds rz_find:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
       
        return [obj.feedID isEqualToNumber:feedID];
        
    }];
    
    return filtered;
    
}

#pragma mark - Setters

- (void)setFeeds:(NSArray<Feed *> *)feeds {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setFeeds:) withObject:feeds waitUntilDone:NO];
        return;
    }
    
    @synchronized (self) {
        ArticlesManager.shared->_feeds = feeds ?: @[];
        ArticlesManager.shared->_feedsWithoutFolders = nil;
    }
    
    // calling this invalidates the pointers we store in folders.
    // calling the folders setter will remap the feeds.
    if (self.folders.count > 0) {
        self.folders = [ArticlesManager.shared folders];
    }
    
    if (ArticlesManager.shared.feeds && _updatingStores == NO) {
        [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self userInfo:nil];
    }
    
    [MyDBManager indexFeeds];
    
}

- (void)setFolders:(NSArray<Folder *> *)folders {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setFolders:) withObject:folders waitUntilDone:NO];
        return;
    }
    
    @synchronized (self) {
        
        if (folders && folders.count) {
            
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
            
            folders = [folders sortedArrayUsingDescriptors:@[descriptor]];
            
        }
        
        ArticlesManager.shared->_folders = folders ?: @[];
        
        [ArticlesManager.shared.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull folder, NSUInteger idxx, BOOL * _Nonnull stopx) {
            
            if (folder.feeds == nil) {
                folder.feeds = [NSPointerArray weakObjectsPointerArray];
                
                NSArray *feedIDs = folder.feedIDs.allObjects;
                
                [feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objx, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    [ArticlesManager.shared.feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull feed, NSUInteger idxx, BOOL * _Nonnull stopx) {
                        
                        if ([feed.feedID isEqualToNumber:objx]) {
                            
                            feed.folderID = folder.folderID;
                            feed.folder = folder;
                            
                            if ([folder.feeds containsObject:feed] == NO) {
                                [folder.feeds addPointer:(__bridge void *)feed];
                            }
                        }
                        
                    }];
                    
                }];
            }
            
        }];
    }
    
}

@end
