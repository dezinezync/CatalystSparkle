//
//  AuthorVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AuthorVC.h"

#define kAuthorDBFilteredView @"authorDBFilteredView"

@interface AuthorVC ()

@property (nonatomic, strong) PagingManager *authorPagingManager;

@property (nonatomic, strong) YapDatabaseFilteredView *dbFilteredView;

@end

@implementation AuthorVC

- (instancetype)initWithFeed:(Feed *)feed author:(NSString *)author {
    
    if (self = [super initWithFeed:feed]) {
        
        self.author = author;
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.author;
    self.pagingManager = self.authorPagingManager;
    
}

- (FeedVCType)type {
    
    return FeedVCTypeAuthor;
    
}

- (void)setAuthor:(NSString *)author {
    
    _author = author;
    
    if (_author) {
        self.restorationIdentifier = formattedString(@"FeedVC-Author-%@-%@", self.feed.feedID, _author);
    }
    
}

- (void)setupDatabases:(YetiSortOption)sortingOption {
    
    weakify(self);
    
    YapDatabaseViewFiltering *filter = [YapDatabaseViewFiltering withRowBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, FeedItem *  _Nonnull object, NSDictionary * _Nullable metadata) {
        
        if ([collection containsString:LOCAL_ARTICLES_COLLECTION] == NO) {
            return NO;
        }
        
        if (metadata != nil && [(NSNumber *)[metadata valueForKey:@"feedID"] isEqualToNumber:self.feed.feedID] == NO) {
            return NO;
        }
        
        BOOL checkOne = NO;
        BOOL checkTwo = YES;
        
        if (object.author != nil) {
            
            strongify(self);
            
            if ([object.author isKindOfClass:NSDictionary.class]) {
                
                if ([[object valueForKeyPath:@"author.name"] isEqualToString:self.author]) {
                    checkOne = YES;
                }
                
            }
            else if ([object.author isKindOfClass:NSString.class]) {
                    
                checkOne = [object.author isEqualToString:self.author];
                
            }
            
        }
        
        if (checkOne == NO) {
            return checkOne;
        }
        
        if ([sortingOption isEqualToString:YTSortUnreadAsc] || [sortingOption isEqualToString:YTSortUnreadDesc]) {
            
            checkTwo = [([metadata valueForKey:@"read"] ?: @(NO)) boolValue] == NO;
            
        }
        
        if (!checkTwo) {
            return NO;
        }
        
        // Filters
        
        if (MyFeedsManager.user.filters.count == 0) {
            return YES;
        }
        
        // compare title to each item in the filters
        
        __block BOOL checkThree = YES;
        
        [MyFeedsManager.user.filters enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            
            if ([object.articleTitle.lowercaseString containsString:obj] == YES) {
                checkThree = NO;
                *stop = YES;
                return;
            }
            
            if (object.summary != nil && [object.summary.lowercaseString containsString:obj] == YES) {
                checkThree = NO;
                *stop = YES;
            }
            
        }];
        
        return checkThree;
        
    }];
    
    self.dbFilteredView = [MyDBManager.database registeredExtension:kAuthorDBFilteredView];
    
    if (self.dbFilteredView == nil) {
        
        YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:DB_FEED_VIEW filtering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
        
        self.dbFilteredView = filteredView;
        
        [MyDBManager.database registerExtension:self.dbFilteredView withName:kAuthorDBFilteredView];
        
    }
    else {
        
        [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kAuthorDBFilteredView];
            
            [tnx setFiltering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
            
        }];
        
    }
    
}

#pragma mark - Subclassed

- (NSString *)filteringViewName {
    return kAuthorDBFilteredView;
}

- (PagingManager *)authorPagingManager {
    
    if (_authorPagingManager == nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(self.sortingOption ?: @0 ) integerValue]);
            
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        NSCharacterSet *urlsafeSet = NSCharacterSet.URLPathAllowedCharacterSet;
        
        NSString *path = formattedString(@"/feeds/%@/author/%@", self.feed.feedID, [self.author stringByAddingPercentEncodingWithAllowedCharacters:urlsafeSet]);
        
        PagingManager * pagingManager = [[PagingManager alloc] initWithPath:path queryParams:params itemsKey:@"articles"];
        
        if (self.noAuth == NO) {
            
            pagingManager.fromDB = YES;
            
            weakify(self);
            
            pagingManager.dbFetchingCB = ^(void (^ _Nonnull completion)(NSArray * _Nullable)) {
              
                strongify(self);
                
                self.controllerState = StateLoading;
                
                dispatch_async(MyDBManager.readQueue, ^{
                    
                    [MyDBManager.countsConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                        
                        YapDatabaseViewTransaction *ext = [transaction extension:kAuthorDBFilteredView];
                        
                        if (ext == nil) {
                            return completion(nil);
                        }
                        
                        NSRange range = NSMakeRange(((self.authorPagingManager.page - 1) * 20) - 1, 20);
                        
                        if (self.authorPagingManager.page == 1) {
                            range.location = 0;
                        }
                        
                        NSMutableArray <FeedItem *> *items = [NSMutableArray arrayWithCapacity:20];
                        
                        [ext enumerateKeysAndObjectsInGroup:GROUP_ARTICLES withOptions:kNilOptions range:range usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
                           
                            [items addObject:object];
                            
                        }];
                        
                        completion(items);
                        
                    }];

                    
                });
                
            };
            
        }
        
        _authorPagingManager = pagingManager;
    }
    
    if (_authorPagingManager.preProcessorCB == nil) {
        _authorPagingManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [obj isKindOfClass:NSDictionary.class] ? [FeedItem instanceFromDictionary:obj] : obj;
            }];
            
            return retval;
            
        };
    }
    
    if (_authorPagingManager.successCB == nil) {
        weakify(self);
        
        _authorPagingManager.successCB = ^{
            strongify(self);
            
            if (!self) {
                return;
            }
            
            [self setupData];
            
            self.controllerState = StateLoaded;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.refreshControl != nil && self.refreshControl.isRefreshing) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1) {
                    
                    [self updateTitleView];
                    
                    if (self.pagingManager.hasNextPage == YES) {
                    
                        [self loadNextPage];
                        
                    }
                    
#if TARGET_OS_MACCATALYST
            if (self->_isRefreshing) {
                self->_isRefreshing = NO;
            }
#endif
                    
                }
            });

        };
    }
    
    if (_authorPagingManager.errorCB == nil) {
        weakify(self);
        
        _authorPagingManager.errorCB = ^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            self.controllerState = StateErrored;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
            })
        };
    }
    
    return _authorPagingManager;
    
}

- (NSString *)emptyViewSubtitle {
    return [NSString stringWithFormat:@"No recent articles from %@ are available.", self.author];
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)_setSortingOption:(YetiSortOption)option {
    
    self.authorPagingManager = nil;
    self.pagingManager = self.authorPagingManager;
    
    [self setupDatabases:option];
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager search:text feedID:self.feed.feedID author:self.author success:self.searchOperationSuccess error:self.searchOperationError];
    
}

#pragma mark - State Restoration

#define kAuthorVCAuthor @"kAuthorVCAuthor"

+ (nullable UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    AuthorVC *vc = (AuthorVC *)[[super class] viewControllerWithRestorationIdentifierPath:identifierComponents coder:coder];
    
    NSString *author = [coder decodeObjectOfClass:NSString.class forKey:kAuthorVCAuthor];
    
    vc.author = author;
    
    return vc;
    
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.author forKey:kAuthorVCAuthor];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    NSString *author = [coder decodeObjectOfClass:NSString.class forKey:kAuthorVCAuthor];
    
    self.author = author;
    
}

@end
