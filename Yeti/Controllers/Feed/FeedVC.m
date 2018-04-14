//
//  FeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+Search.h"
#import "ArticleCell.h"
#import "ArticleVC.h"
#import "YetiConstants.h"

#import "FeedsManager.h"

#import <DZKit/EFNavController.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

#import "FeedSearchResults.h"
#import "ArticleProvider.h"

#import "FeedHeaderView.h"

@interface FeedVC () <DZDatasource, ArticleProvider> {
    UIImageView *_barImageView;
}

@property (nonatomic, weak) FeedHeaderView *headerView;

@end

@implementation FeedVC

- (instancetype)initWithFeed:(Feed *)feed
{
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.feed = feed;
        _canLoadNext = YES;
        _page = 0;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.feed.title;
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    self.DS.data = self.feed.articles;
    
    self.DS.addAnimation = UITableViewRowAnimationFade;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCell.class) bundle:nil] forCellReuseIdentifier:kArticleCell];
    
    self.tableView.tableFooterView = [UIView new];
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"done_all"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:)];
    allRead.accessibilityHint = @"Mark all articles are read";
    self.navigationItem.rightBarButtonItem = allRead;
    
    // Search Controller setup
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search articles";
        searchController.searchBar.accessibilityHint = @"Search loaded articles";
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        self.navigationItem.searchController = searchController;
    }
    
    if (self.feed.authors && self.feed.authors.count > 1) {
        [self setupHeaderView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)definesPresentationContext
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // makes sure search bar is visible when it appears
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (self.headerView) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            UIView *searchBarSuperview = self.navigationItem.searchController.searchBar.superview;
            
            SEL imagesSelector = NSSelectorFromString(@"findHairlineImageViewUnder:");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            UIImageView *image = [self performSelector:imagesSelector withObject:searchBarSuperview];
#pragma clang diagnostic pop
            self->_barImageView = image;
            
            if (image) {
                if (self->_headerView) {
                    self->_headerView.shadowImage = image;
                }
                
                [UIView transitionWithView:image duration:0.2 options:kNilOptions animations:^{
                    image.hidden = YES;
                } completion:nil];
            }
            
        });
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        // ensures user can dismiss search bar on scroll
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    });
}

- (void)_setToolbarHidden {
    self.navigationController.toolbarHidden = YES;
}

- (void)setupHeaderView
{
    
    [self ef_hideNavBorder:self.navigationController.transitionCoordinator];
    
    if (_headerView)
        return;
    
    FeedHeaderView *headerView = [[FeedHeaderView alloc] initWithNib];
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.f);
    
    [headerView configure:self.feed];
    
    self.tableView.tableHeaderView = headerView;
    
    _headerView = headerView;
}

#pragma mark - Actions

- (void)didTapAllRead:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Mark All Read" message:@"Are you sure you want to mark all articles as read?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    weakify(self);
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [MyFeedsManager articles:(NSArray <FeedItem *> *)self.DS.data markAsRead:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
        });
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular){
    
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.barButtonItem = sender;
        
    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
    
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:kArticleCell forIndexPath:indexPath];
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    // Configure the cell...
    [cell configure:item customFeed:[self isMemberOfClass:NSClassFromString(@"CustomFeedVC")]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    vc.providerDelegate = self;
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        EFNavController *nav = [[EFNavController alloc] initWithRootViewController:vc];
        
        [self.splitViewController showDetailViewController:nav sender:self];
        // hide the primary controller
        UIBarButtonItem *item = [self.splitViewController displayModeButtonItem];
        [UIApplication.sharedApplication sendAction:item.action to:item.target from:nil forEvent:nil];
    }
    else {
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        item.read = YES;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    });
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    weakify(self);
    
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Open in Browser" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        strongify(self);
        
        FeedItem * item = [self.DS objectAtIndexPath:indexPath];
        
        NSString *url = [item articleURL];
        
        NSString *externalApp = [[NSUserDefaults.standardUserDefaults valueForKey:ExternalBrowserAppScheme] lowercaseString];
        NSString *scheme = nil;
        
        if ([externalApp isEqualToString:@"safari"]) {
            scheme = url;
        }
        else if ([externalApp isEqualToString:@"chrome"]) {
            // googlechromes for https, googlechrome for http
            if ([url containsString:@"https:"]) {
                scheme = formattedString(@"googlechromes://%@", [url stringByReplacingOccurrencesOfString:@"https://" withString:@""]);
            }
            else {
                scheme = formattedString(@"googlechrome://%@", [url stringByReplacingOccurrencesOfString:@"http://" withString:@""]);
            }
        }
        else if ([externalApp isEqualToString:@"firefox"]) {
            scheme = formattedString(@"firefox://open-url?url=%@", url);
        }
        
        DDLogDebug(@"External App:%@\nURL:%@\nScheme:%@", externalApp, url, scheme);
        
        if (!scheme) {
            completionHandler(NO);
            return;
        }
        
        asyncMain(^{
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:scheme] options:@{} completionHandler:completionHandler];
        })
    }];
    
    action.backgroundColor = self.view.tintColor;
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[action]];
    config.performsFirstActionWithFullSwipe = YES;
    
    return config;
}

#pragma mark - <ScrollLoading>

- (void)yt_scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.headerView) {
        CGFloat yPoint = floor(scrollView.contentOffset.y);
        
//        DDLogDebug(@"%@", @(yPoint));
        if (yPoint >= 0.f && _barImageView.isHidden) {
            _barImageView.hidden = NO;
        }
        else if (yPoint < 0.f && !_barImageView.isHidden) {
            _barImageView.hidden = YES;
        }
    }
}

- (void)loadNextPage
{
    self.loadingNext = YES;
    
    weakify(self);
    
    [MyFeedsManager getFeed:self.feed page:(_page+1) success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        if (!responseObject.count) {
            self->_canLoadNext = NO;
        }
        
        asyncMain(^{
            self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
        });
        
        self->_page++;
        self.loadingNext = NO;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        if (!self)
            return;
        
        self.loadingNext = NO;
    }];
}

- (BOOL)cantLoadNext
{
    return !_canLoadNext;
}

#pragma mark - <ArticleProvider>

// the logic for the following two methods is inversed
// since the articles are displayed in reverse chronological order
- (BOOL)hasNextArticleForArticle:(FeedItem *)item
{
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return NO;
    
    return index > 0;
}

- (BOOL)hasPreviousArticleForArticle:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return NO;
    
    return (index < (((NSArray <FeedItem *> *)self.DS.data).count - 1));
}

- (FeedItem *)previousArticleFor:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index > 0) {
        index--;
        return ((NSArray <FeedItem *> *)self.DS.data)[index];
    }
    
    return nil;
}

- (FeedItem *)nextArticleFor:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index < (((NSArray <FeedItem *> *)self.DS.data).count - 1)) {
        index++;
        return ((NSArray <FeedItem *> *)self.DS.data)[index];
    }
    
    return nil;
}

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read
{
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:article];
    
    if (index == NSNotFound)
        return;
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        self.feed.articles[index].read = read;
        [(NSArray <FeedItem *> *)self.DS.data objectAtIndex:index].read = read;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    });
}

- (void)didChangeToArticle:(FeedItem *)item
{
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:item];
    
    if (index == NSNotFound)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    if (!item.isRead) {
        [self userMarkedArticle:item read:YES];
    }
    else {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

@end
