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

@end

@implementation DetailAuthorVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.collectionView registerClass:DetailAuthorHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailAuthorHeaderView];
    
}

- (void)setAuthor:(Author *)author {
    _author = author;
    
    if (author) {
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
    
    
    self.headerView.author = self.author;
    
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available from %@", self.author.name);
}

- (void)reloadHeaderView {
    
    [(DetailAuthorHeaderView *)[self.headerView superview] setupAppearance];
    
}

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    self.loadingNext = YES;
    
    weakify(self);
    
    NSInteger page = self.page + 1;
    
    [MyFeedsManager articlesByAuthor:self.author.authorID feedID:self.feed.feedID page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self.page = page;
        
        if (responseObject == nil || responseObject.count == 0) {
            self->_canLoadNext = NO;
        }
        else {
            
            if (@available(iOS 13, *)) {
                NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
                [snapshot appendItemsWithIdentifiers:responseObject];
                
                [self.DDS applySnapshot:snapshot animatingDifferences:YES];
            }
            else {
                if (page == 1 && self.DS.data.count) {
                    self.DS.data = responseObject;
                }
                else {
                    self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
                }
            }
            
            self.loadingNext = NO;
            
            if (page == 1 && self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self loadNextPage];
            }
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        self.loadingNext = NO;
    }];
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
    
    if (@available(iOS 13, *)) {
        [coder encodeObject:self.DDS.snapshot.itemIdentifiers forKey:kBAuthorDS];
    }
    else {
        [coder encodeObject:self.DS.data forKey:kBAuthorDS];
    }
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray *data = [coder decodeObjectForKey:kBAuthorDS];
    
    if (data) {
        [self setupLayout];
        
        if (@available(iOS 13, *)) {
            NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
            
            if (snapshot.numberOfSections == 0) {
                [snapshot appendSectionsWithIdentifiers:@[@"main"]];
            }
            
            [snapshot appendItemsWithIdentifiers:data];
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else {
            self.DS.data = data;
        }
    }
    
}

@end
