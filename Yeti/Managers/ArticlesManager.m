//
//  ArticlesManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/08/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ArticlesManager.h"
#import <DZkit/NSArray+RZArrayCandy.h>

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

- (void)willBeginUpdatingStore {
    
    if (_updatingStores == YES) {
        return;
    }
    
    _updatingStores = YES;
    
}

- (void)didFinishUpdatingStore {
    
    if (_updatingStores == NO) {
        return;
    }
    
    _updatingStores = NO;
    
    self.feedsWithoutFolders = nil;
    
    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self userInfo:nil];
    
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

- (NSArray <FeedItem *> *)bookmarks {
    
    if (_bookmarks == nil || _bookmarks.count == 0) {
        
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
        BOOL isDir;
        
        if (![manager fileExistsAtPath:directory isDirectory:&isDir]) {
            NSError *error = nil;
            if (![manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Error creating bookmarks directory: %@", error);
            }
        }
        
        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:directory];
        NSArray *objects = enumerator.allObjects;
//            NSLogDebug(@"Have %@ bookmarks", @(objects.count));
        
        NSMutableArray <FeedItem *> *bookmarkedItems = [NSMutableArray arrayWithCapacity:objects.count+1];
        
        NSError *error = nil;
        
        for (NSString *path in objects) { @autoreleasepool {
            error = nil;
            NSString *filePath = [directory stringByAppendingPathComponent:path];
            FeedItem *item = nil;
            
            @try {
                NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
                
                if (fileData != nil) {
                    
                    item = [NSKeyedUnarchiver unarchivedObjectOfClass:FeedItem.class fromData:fileData error:&error];
                    
                    if (error != nil) {
                        NSLog(@"Error loading bookmark file from: %@\n%@", filePath, error);
                    }
                    
                    if (item == nil) {
                        // it could be archived using the old API. Try that.
                        item = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
                    }
                    
                }
            }
            @catch (NSException *exception) {
                NSLog(@"Bookmark load exception: %@", exception);
            }
            
            if (item) {
                [bookmarkedItems addObject:item];
            }
        } }
        
        _bookmarks = [[bookmarkedItems sortedArrayUsingSelector:@selector(compare:)] rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
            obj.bookmarked = YES;
            return obj;
        }];
    }
    
    return _bookmarks;
    
}

- (Feed *)feedForID:(NSNumber *)feedID {
    
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
    self.folders = [ArticlesManager.shared folders];
    
    if (ArticlesManager.shared.feeds && _updatingStores == NO) {
        [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self userInfo:nil];
    }
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

#pragma mark - <UIStateRestoring>

- (Class)objectRestorationClass {
    return ArticlesManager.class;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {

    if (self = [super init]) {
        
    }
    
    return self;

}

+ (nullable id<UIStateRestoring>) objectWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    
    ArticlesManager *shared = [[ArticlesManager alloc] initWithCoder:coder];
    
    ArticlesManager.shared = shared;
    
    return shared;
    
}

@end
