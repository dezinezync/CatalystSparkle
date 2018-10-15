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
        self.restorationIdentifier = formattedString(@"%@-%@-%@", NSStringFromClass(self.class), self.feed.feedID, author.authorID);
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

- (void)setupLayout {
    
    CGFloat padding = self.flowLayout.minimumInteritemSpacing;
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.flowLayout.sectionInset = UIEdgeInsetsMake(padding, 0.f, padding, 0.f);
    }
    else {
        self.flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding/2.f, padding, padding/2.f);
    }
    
    self.flowLayout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    
    self.flowLayout.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 40.f);
    
}

- (void)reloadHeaderView {
    
    [(DetailAuthorHeaderView *)[self.headerView superview] setupAppearance];
    
}

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    NSInteger page = _page + 1;
    
    [MyFeedsManager articlesByAuthor:self.author.authorID feedID:self.feed.feedID page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self->_page = page;
        
        if (![responseObject count]) {
            self->_canLoadNext = NO;
        }
        
        if (page == 1 && self.DS.data.count) {
            self.DS.data = responseObject;
        }
        else {
            self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
        }
        
        self.loadingNext = NO;
        
        if (page == 1 && self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self loadNextPage];
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        self.loadingNext = NO;
    }];
}

#pragma mark - State Restoration

NSString * const kBAuthorData = @"AuthorData";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Author *author = [coder decodeObjectForKey:kBAuthorData];
    
    if (author) {
        DetailAuthorVC *vc = [[DetailAuthorVC alloc] init];
        vc.author = author;
        vc.customFeed = FeedTypeFeed;
        return vc;
    }
    
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.author forKey:kBAuthorData];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    Author *author = [coder decodeObjectForKey:kBAuthorData];
    
    if (author) {
        self.author = author;
    }
    
}

@end
