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
        self.page = 0;
        
        self.customFeed = FeedTypeFolder;
        
        self.sizeCache = @[].mutableCopy;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.folder.title;
    
    if (@available(iOS 13, *)) {
        self.controllerState = StateDefault;
    }
    else {
        self.DS.state = DZDatasourceDefault;
    }
    
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
    
    if (@available(iOS 13, *)) {
        if (self.controllerState == StateLoading) {
            return;
        }
    }
    else {
    
        if (self.DS.state != DZDatasourceLoading)
            return;
    }
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    if (@available(iOS 13, *)) {
        self.controllerState = StateLoading;
    }
    else {
        self.DS.state = DZDatasourceLoading;
    }
    
    weakify(self);
    
    NSInteger page = self.page + 1;
    
    YetiSortOption sorting = SharedPrefs.sortingOption;
    
    [MyFeedsManager folderFeedFor:self.folder sorting:sorting page:page success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self.page = page;
        
        if (responseObject == nil || [responseObject count] == 0) {
            self->_canLoadNext = NO;
        }
        else {
            
            if (@available(iOS 13, *)) {
                
                NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
                [snapshot appendItemsWithIdentifiers:responseObject];
                
                [self.DDS applySnapshot:snapshot animatingDifferences:YES];
                
                self.controllerState = StateLoaded;
            }
            else {
                if (page == 1 || self.DS.data == nil) {
                    self.DS.data = responseObject;
                }
                else {
                    self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
                }
                
                self.DS.state = DZDatasourceLoaded;
            }
        
            if (page == 1 && self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [self loadNextPage];
            }
        }
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        if (@available(iOS 13, *)) {
            self.controllerState = StateErrored;
        }
        else {
            self.DS.state = DZDatasourceError;
            
            if (self.DS.data == nil || [self.DS.data count] == 0) {
                // the initial load has failed.
                self.DS.data = @[];
            }
        }
    
    }];
}

#pragma mark - State Restoration

#define kBFolderData @"FolderData"
#define kBFolderObj @"FolderObject"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    Folder *folder = [coder decodeObjectForKey:kBFolderObj];
    
    DetailFolderVC *vc;
    
    if (folder != nil) {
        vc = [[DetailFolderVC alloc] initWithFolder:folder];
        vc.customFeed = FeedTypeFolder;
    }
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    if (@available(iOS 13, *)) {
        [coder encodeObject:self.DDS.snapshot.itemIdentifiers forKey:kBFolderData];
    }
    else {
        [coder encodeObject:self.DS.data forKey:kBFolderData];
    }
    
    [coder encodeObject:self.folder forKey:kBFolderObj];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray <FeedItem *> *items = [coder decodeObjectForKey:kBFolderData];
    
    if (items) {
        [self setupLayout];
        
        if (@available(iOS 13, *)) {
            NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
            [snapshot appendSectionsWithIdentifiers:@[@"main"]];
            [snapshot appendItemsWithIdentifiers:items];
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else {
            self.DS.data = items;
        }
    }
    
}


@end
