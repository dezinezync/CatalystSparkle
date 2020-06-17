//
//  AuthorVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AuthorVC.h"

@interface AuthorVC ()

@property (nonatomic, strong) PagingManager *authorPagingManager;

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

#pragma mark - Subclassed

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
        
        _authorPagingManager = pagingManager;
    }
    
    if (_authorPagingManager.preProcessorCB == nil) {
        _authorPagingManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
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
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1 && self.pagingManager.hasNextPage == YES) {
                    [self loadNextPage];
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
