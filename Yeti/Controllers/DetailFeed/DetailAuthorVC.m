//
//  DetailAuthorVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailAuthorVC.h"
#import "Feed.h"
#import "FeedsManager.h"
#import "DetailAuthorHeaderView.h"

@interface DetailAuthorVC ()

@property (nonatomic, weak) AuthorHeaderView *headerView;
@property (nonatomic, strong) PagingManager *authorPagingManager;

@end

@implementation DetailAuthorVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.collectionView registerClass:DetailAuthorHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailAuthorHeaderView];
    
}

- (void)setAuthor:(Author *)author {
    _author = author;
    
    if (author) {
        self.title = author.name;
        self.restorationIdentifier = NSStringFromClass(self.class);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    DetailAuthorHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailAuthorHeaderView forIndexPath:indexPath];
    
    self.headerView = view.headerContent;
    [self setupHeaderView];
    
    return view;
    
}

- (void)setupHeaderView {
    
    if (self.headerView == nil)
        return;
    
    self.headerView.feed = self.feed;
    self.headerView.author = self.author;
    
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available from %@", self.author.name);
}

- (void)reloadHeaderView {
    
    [(DetailAuthorHeaderView *)[self.headerView superview] setupAppearance];
    
}

- (PagingManager *)pagingManager {
    
    return self.authorPagingManager;
    
}

- (PagingManager *)authorPagingManager {
    
    if (_authorPagingManager == nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(_sortingOption ?: @0 ) integerValue]);
            
        #if TESTFLIGHT == 0
            if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
                params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
            }
        #endif
        
        NSString *path = formattedString(@"/feeds/%@/author/%@", self.feed.feedID, self.author.authorID);
        
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
            DDLogError(@"%@", error);
            
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

#pragma mark - State Restoration

#define kBAuthorData @"AuthorData"
#define kBAuthorDS @"AuthorDS"
#define kBAuthorFeed @"AuthorFeed"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Author *author = [coder decodeObjectForKey:kBAuthorData];
    Feed *feed = [coder decodeObjectForKey:kBAuthorFeed];

    if (author != nil && feed != nil) {
        DetailAuthorVC *vc = [[DetailAuthorVC alloc] initWithFeed:feed];
        vc.author = author;
        vc.customFeed = FeedTypeFeed;

        return vc;
    }

    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.author forKey:kBAuthorData];
    
    [coder encodeObject:self.feed forKey:kBAuthorFeed];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    self.feed = [coder decodeObjectForKey:kBAuthorFeed];
    self.author = [coder decodeObjectForKey:kBAuthorData];
    
    [super decodeRestorableStateWithCoder:coder];
    
}

@end
