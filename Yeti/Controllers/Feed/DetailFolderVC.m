//
//  DetailFolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFolderVC.h"
#import "FeedsManager.h"

@interface DetailFolderVC ()

@end

@implementation DetailFolderVC

+ (UINavigationController *)instanceWithFolder:(Folder *)folder {
    
    DetailFolderVC *instance = [[DetailFolderVC alloc] initWithFolder:folder];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"DetailFolderNavVC";
    
    return nav;
    
}

- (instancetype)initWithFolder:(Folder *)folder {
    
    if (self = [super initWithNibName:NSStringFromClass(DetailFeedVC.class) bundle:nil]) {
        self.folder = folder;
        _canLoadNext = YES;
        _page = 0;
        
        self.customFeed = FeedTypeFolder;
        
        self.sizeCache = @{}.mutableCopy;
        
        self.restorationIdentifier = formattedString(@"%@-%@", NSStringFromClass(self.class), folder.folderID);
        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.folder.title;
    
}

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available in %@", self.folder.title);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)setupHeaderView { }

- (void)reloadHeaderView { }

- (void)setupLayout {
    
    self->_shouldShowHeader = NO;
    
    [super setupLayout];
    
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
    
    NSInteger page = _page + 1;
    
    YetiSortOption sorting = [[NSUserDefaults standardUserDefaults] valueForKey:kDetailFeedSorting];
    
    [MyFeedsManager folderFeedFor:self.folder sorting:sorting page:page success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self->_page = page;
        
        if (![responseObject count]) {
            self->_canLoadNext = NO;
            self.DS.data = self.DS.data ?: @[];
        }
        
        if (page == 1 || self.DS.data == nil) {
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
        
        if (self.DS.data == nil || [self.DS.data count] == 0) {
            // the initial load has failed.
            self.DS.data = @[];
        }
        
        self.loadingNext = NO;
    }];
}

#pragma mark - State Restoration

NSString * const kBFolderData = @"FolderData";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    DetailFolderVC *vc = [[DetailFolderVC alloc] init];
    vc.customFeed = FeedTypeFolder;
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.DS.data forKey:kBFolderData];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray <FeedItem *> *items = [coder decodeObjectForKey:kBFolderData];
    
    if (items) {
        self.DS.data = items;
        self.customFeed = FeedTypeFolder;
    }
    
}


@end
