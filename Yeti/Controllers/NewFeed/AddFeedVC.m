//
//  AddFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "AddFeedVC.h"
#import "FeedsSearchResults.h"
#import "YetiThemeKit.h"
#import "FeedsManager.h"
#import "AddFeedCell.h"

@interface AddFeedVC () <UISearchControllerDelegate, UISearchBarDelegate, DZDatasource, UISearchResultsUpdating, ScrollLoading>

@property (nonatomic, strong) UIActivityIndicatorView *loaderView;
@property (nonatomic, strong) UILabel *errorLabel;

@property (nonatomic, strong, readwrite) DZBasicDatasource *DS;

@property (atomic, assign) NSInteger selected;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, assign) BOOL loadedLast;

@end

@implementation AddFeedVC

+ (UINavigationController *)instanceInNavController {
    
    AddFeedVC *vc = [[AddFeedVC alloc] init];
    NewFeedDeckController *nav = [[NewFeedDeckController alloc] initWithRootViewController:vc];
    
    return nav;
}

- (BOOL)definesPresentationContext
{
    return YES;
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Add Feed";
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    [self setupSearchController];
    [self setupDefaultViews];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    // https://stackoverflow.com/a/28527114/1387258
    [self.navigationItem.searchController setActive:YES];
    
}

#pragma mark - State

- (void)setState:(AddFeedState)state {
    
    if ([NSThread isMainThread] == NO) {
        [self performSelectorOnMainThread:@selector(setState:) withObject:@(state) waitUntilDone:NO];
        return;
    }
    
    _state = state;
    
    
    
}

#pragma mark - <UITableViewDelegate>

- (UIView *)viewForEmptyDataset {
    
    if (self.searchBar.text == nil || [self.searchBar.text isBlank]) {
        return nil;
    }
    
    if (self.DS.state == DZDatasourceLoading && self.page == 0) {
        return self.loaderView;
    }
    
    if (self.DS.state == DZDatasourceError && self.page == 0) {
        [self setupErrorLabel];
        return self.errorLabel;
    }
    
    return nil;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    AddFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:kAddFeedCell forIndexPath:indexPath];
    
    [cell configure:feed];
    
    cell.accessoryType = self.selected == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectedBackgroundView.backgroundColor = [[[YTThemeKit theme] tintColor] colorWithAlphaComponent:0.2f];
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
t
}

#pragma mark - Setups

- (void)setupSearchController {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.hidesNavigationBarDuringPresentation = NO;
    searchController.obscuresBackgroundDuringPresentation = NO;
    
    searchController.searchBar.placeholder = @"Website or Feed URL";
    searchController.searchBar.scopeButtonTitles = @[@"URL", @"Name", @"Keywords"];
    searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceDefault;
    
    self.navigationItem.searchController = searchController;
    
    self.searchBar = self.navigationItem.searchController.searchBar;
    self.searchBar.delegate = self;
}

- (void)setupDefaultViews {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.backgroundColor;
    self.tableView.backgroundColor = theme.tableColor;
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerClass:AddFeedCell.class forCellReuseIdentifier:kAddFeedCell];
    self.DS.addAnimation = UITableViewRowAnimationTop;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
}

- (void)setupErrorLabel {
    
}

#pragma mark - Getters

- (UIActivityIndicatorView *)loaderView {
    
    if (_loaderView == nil) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        UIActivityIndicatorViewStyle style = theme.isDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        
        UIActivityIndicatorView *loader = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [loader sizeToFit];
        loader.translatesAutoresizingMaskIntoConstraints = NO;
        loader.hidesWhenStopped = YES;
        
        _loaderView = loader;
    }
    
    return _loaderView;
    
}

- (UILabel *)errorLabel {
    
    if (_errorLabel == nil) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 12.f, self.view.bounds.size.width - (24.f), 0.f)];
        label.preferredMaxLayoutWidth = label.bounds.size.width;
        label.textColor = theme.subtitleColor;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        _errorLabel = label;
    }
    
    return _errorLabel;
    
}

#pragma mark - <UISearchControllerDelegate>

- (void)didPresentSearchController:(UISearchController *)searchController {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchController.searchBar becomeFirstResponder];
    });
    
}

#pragma mark - <UISearchBarDelegate>

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    
    self.searchBar.placeholder = @[@"Website or Feed URL", @"Website Name", @"Keywords"][selectedScope];
    
    [self searchBarTextDidEndEditing:self.searchBar];
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
    if (self.networkTask != nil) {
        [self.networkTask cancel];
    }
    
    NSString *query = self.searchBar.text;
    
    if (query == nil || [query isBlank]) {
        return;
    }
    
    if (query.length < 3) {
        return;
    }
    
    if (self.searchBar.selectedScopeButtonIndex == 0) {
        // add the feed normally
        
        return;
    }
    
    self.page = 0;
    self.query = query;
    self.loadedLast = NO;
    self.selected = NSNotFound;
    
    self.DS.data = @[];
    self.DS.state = DZDatasourceLoaded;
    
    [self loadNextPage];
}

#pragma mark - <ScrollLoading>

- (BOOL)isLoadingNext {
    return self.DS.state == DZDatasourceLoading;
}

- (BOOL)cantLoadNext {
    return self.loadedLast || self.DS.state == DZDatasourceError;
}

- (void)loadNextPage {
    
    if (self.DS.state != DZDatasourceLoaded) {
        return;
    }
    
    self.DS.state = DZDatasourceLoading;
    
    NSInteger page = self.page + 1;
    
    self.networkTask = [MyFeedsManager search:self.query scope:self.searchBar.selectedScopeButtonIndex page:page success:^(NSArray <Feed *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.DS.state = DZDatasourceLoaded;
        
        if (page == 1) {
            self.DS.data = responseObject;
        }
        else {
            NSArray *existing = self.DS.data;
            NSArray *newSet = [existing arrayByAddingObjectsFromArray:responseObject];
            
            self.DS.data = newSet;
        }
        
        self.loadedLast = responseObject.count < 20;
        
        self.page = page;
        
        DDLogDebug(@"%ld search results", responseObject.count);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.DS.state = DZDatasourceError;
        
        if (page == 1) {
            self.errorTitle = @"Error Loading Results";
            self.errorBody = error.localizedDescription;
        }
        else {
            // Do nothing
            DDLogError(@"Error loading search query: %@", error);
        }
        
    }];
    
}

#pragma mark - <UISearchControllerDelegate>

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {}

@end
