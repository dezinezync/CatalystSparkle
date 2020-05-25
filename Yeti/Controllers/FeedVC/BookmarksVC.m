//
//  BookmarksVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "BookmarksVC.h"

@interface BookmarksVC () {
    BOOL _reloadData;
}

@property (nonatomic, strong) NSArray <FeedItem *> * articles;

@end

@implementation BookmarksVC

- (instancetype)init {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        self.type = FeedVCTypeBookmarks;
        
        self.restorationClass = [self class];
        self.restorationIdentifier = @"BookmarksVC";
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Bookmarks";
    
    weakify(self);
    
    [self.bookmarksManager addObserver:self name:BookmarksDidUpdateNotification callback:^{
       
        strongify(self);
        
        if (self->_reloadData == NO) {
            self->_reloadData = YES;
        }
        
    }];
    
}

- (void)dealloc {
    
    [self.bookmarksManager removeObserver:self name:BookmarksDidUpdateNotification];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self->_reloadData == YES || (self.DS.snapshot.numberOfItems == 0 && self.bookmarksManager.bookmarksCount != 0)) {
        
        self->_reloadData = NO;
        
        [self setupData];
        
    }
    
}

#pragma mark - Subclassed

- (void)setupNavigationBar {
    
    [super setupNavigationBar];
    
    self.navigationItem.searchController.searchBar.scopeButtonTitles = @[@"Local"];
    self.navigationItem.searchController.searchBar.showsScopeBar = NO;
    
}

- (PagingManager *)pagingManager {
    return nil;
}

- (void)setupData {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (self.bookmarksManager == nil) {
        return;
    }
    
    NSArray <FeedItem *> * articles = self.bookmarksManager.bookmarks;
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:(SharedPrefs.sortingOption == YTSortAllAsc)];
    
    self.articles = [articles sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    @try {
        
        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@0]];
        [snapshot appendItemsWithIdentifiers:self.articles intoSectionWithIdentifier:@0];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
        
        self.controllerState = StateLoaded;
        
    }
    @catch (NSException *exc) {
        NSLog(@"Exception updating bookmarks articles: %@", exc);
        self.controllerState = StateErrored;
    }
    
}

- (NSString *)emptyViewSubtitle {
    return @"Bookmarking a great way to save articles for referencing later or the content you really enjoyed reading.";
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)updateSortingOptionTo:(YetiSortOption)option sender:(UIBarButtonItem *)sender {
    
    self.sortingOption = option;
    
    UIColor *tintColor = nil;
    UIImage *image = [SortImageProvider imageForSortingOption:option tintColor:&tintColor];
    
    sender.image = image;
    sender.tintColor = tintColor;
    
}

- (void)setSortingOption:(YetiSortOption)sortingOption {
    
    [super setSortingOption:sortingOption];
    
    [self setupData];
    
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    weakify(self);
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [self updateSortingOptionTo:YTSortAllDesc sender:sender];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [self updateSortingOptionTo:YTSortAllAsc sender:sender];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        
        UIColor *tintColor = nil;
        UIImage * image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc tintColor:&tintColor];
        
        [allDesc setValue:image forKeyPath:@"image"];
        
        tintColor = nil;
        image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc tintColor:&tintColor];
        
        [allAsc setValue:image forKeyPath:@"image"];


    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (void)_search:(NSString *)text scope:(NSInteger)scope {
 
    // scope will always be 0 here
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    
    NSArray <FeedItem *> * items = self.articles;
    
    items = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
        
        NSString *title = obj.articleTitle.lowercaseString;
        
        if ([title isEqualToString:text] || [title containsString:text]) {
            return YES;
        }
        
        if (obj.summary != nil) {
            
            NSString *summary = [obj.summary lowercaseString];
            
            if ([summary containsString:text]) {
                return YES;
            }
            
        }
        
        NSString *blogTitle = obj.blogTitle.lowercaseString;
        
        if ([blogTitle isEqualToString:text] || [blogTitle containsString:text]) {
            return YES;
        }
        
        return NO;
        
    }];
    
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    [snapshot appendItemsWithIdentifiers:items intoSectionWithIdentifier:@0];
    
    [self.DS applySnapshot:snapshot animatingDifferences:YES];
    
}

@end
