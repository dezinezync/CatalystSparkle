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
#import "FeedVC.h"

#import <DZKit/NSArray+Safe.h>
#import <DZKit/AlertManager.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "AppDelegate+Routing.h"

@interface AddFeedVC () <UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, ScrollLoading>

@property (nonatomic, strong) UIActivityIndicatorView *loaderView;
@property (nonatomic, strong) UILabel *errorLabel;

@property (nonatomic, assign) NSInteger selected;
@property (nonatomic, copy) NSString *query;
@property (nonatomic, assign) BOOL loadedLast;

@property (nonatomic, weak) UIBarButtonItem *cancelButton;

@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationGenerator;

@end

@implementation AddFeedVC

+ (UINavigationController *)instanceInNavController {
    
    AddFeedVC *vc = [[AddFeedVC alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
#if !TARGET_OS_MACCATALYST
    nav.modalInPresentation = YES;
#endif
    
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
    
    self.selected = NSNotFound;
    
    self.navigationController.navigationBar.prefersLargeTitles = NO;
//
//    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
//    self.DS.delegate = self;
    
    [self setupSearchController];
    [self setupDefaultViews];
    
#if TARGET_OS_MACCATALYST
    self.navigationController.navigationBar.translucent = NO;
#endif
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    // https://stackoverflow.com/a/28527114/1387258
    [self.navigationItem.searchController setActive:YES];
    
}

#pragma mark - Setters

- (void)setSelected:(NSInteger)selected
{
    _selected = selected;
    
    if (_selected == NSNotFound) {
        [self.cancelButton setTitle:@"Close"];
    }
    else {
        [self.cancelButton setTitle:@"Done"];
    }
}

#pragma mark - <UITableViewDelegate>

- (void)setErrorLabelForDefaultState {
    
    NSUInteger index = self.searchBar.selectedScopeButtonIndex ?: 0;
    
    self.errorTitle = @[@"Enter URL to Begin", @"Begin Your Search", @"Begin Your Search"][index];
    self.errorBody = @[@"Enter the website or feed URL to add it to your list.", @"Begin by typing the name of the website you want to search for.", @"Begin by typing a keyword. Separate multiple keywords with a space."][index];
    
    [self setupErrorLabel];
}

- (UIView *)viewForEmptyDataset {
    
    if (self.searchBar.text == nil || [self.searchBar.text isBlank]) {
        
        [self setErrorLabelForDefaultState];
        
        return self.errorLabel;
    }
    
//    if (self.DS.state == DZDatasourceLoading) {
//        [self.loaderView startAnimating];
//        return self.loaderView;
//    }
//    else {
//        if ([self.loaderView isAnimating]) {
//            [self.loaderView stopAnimating];
//        }
//    }
//
//    if (self.DS.state == DZDatasourceError && self.page == 0) {
//        [self setupErrorLabel];
//        return self.errorLabel;
//    }
    
    // the user entered a URL which has no RSS feeds on it
    if (self.searchBar.selectedScopeButtonIndex == 0) {
        self.errorTitle = @"No Feeds Found";
        self.errorBody = @"No RSS Feeds were found on this website. Please check the URL or try a different website.";
        
        [self setupErrorLabel];
        return self.errorLabel;
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    Feed *feed = [self.DS objectAtIndexPath:indexPath];
//
    AddFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:kAddFeedCell forIndexPath:indexPath];
//
//    [cell configure:feed];
//
//    cell.accessoryType = self.selected == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
//
    return cell;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        cell.separatorInset = UIEdgeInsetsZero;
    }
    else {
        cell.separatorInset = UIEdgeInsetsMake(0, tableView.readableContentGuide.layoutFrame.origin.x, 0, tableView.readableContentGuide.layoutFrame.origin.x);
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.searchBar.selectedScopeButtonIndex == 0) {
        
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        if (self.selected != NSNotFound) {
            AddFeedCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.selected inSection:0]];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        if (self.selected == indexPath.row) {
            self.selected = NSNotFound;
        }
        else {
            self.selected = indexPath.row;
            AddFeedCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        
        return;
        
    }
    
    if (self.searchBar.isFirstResponder == YES) {
        [self.searchBar resignFirstResponder];
    }
    
//    Feed *feed = [self.DS objectAtIndexPath:indexPath];
//
//    if (feed) {
//        FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
//        vc.exploring = YES;
//
//        [self.navigationController pushViewController:vc animated:YES];
//    }
//    else {
//        [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    }

}

#pragma mark - Setups

- (void)setupSearchController {
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.hidesNavigationBarDuringPresentation = YES;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.definesPresentationContext = YES;
    
    searchController.searchBar.scopeButtonTitles = @[@"URL", @"Name", @"Keywords"];
    
    searchController.automaticallyShowsScopeBar = YES;
    
    self.navigationItem.searchController = searchController;
    
    self.searchBar = self.navigationItem.searchController.searchBar;
    self.searchBar.delegate = self;
    
    [self searchBar:searchController.searchBar selectedScopeButtonIndexDidChange:0];
}

- (void)setupDefaultViews {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.backgroundColor;
    self.tableView.backgroundColor = theme.tableColor;
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(AddFeedCell.class) bundle:nil] forCellReuseIdentifier:kAddFeedCell];
//    self.DS.addAnimation = UITableViewRowAnimationTop;
//    self.DS.deleteAnimation = UITableViewRowAnimationFade;
//    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(didTapClose:)];
    
    self.navigationItem.rightBarButtonItem = cancelButton;
    self.cancelButton = self.navigationItem.rightBarButtonItem;
    
}

- (void)setupErrorLabel {
    
    NSMutableString *formatted = [[NSMutableString alloc] init];
    if (self.errorTitle) {
        [formatted appendString:self.errorTitle];
        [formatted appendString:@"\n"];
    }
    
    if (self.errorBody) {
        [formatted appendString:self.errorBody];
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    para.lineHeightMultiple = 1.4f;
    para.alignment = self.errorLabel.textAlignment;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if (font != nil) {
        [attributes setObject:font forKey:NSFontAttributeName];
    }
    
    if (theme.subtitleColor != nil) {
        [attributes setObject:theme.subtitleColor forKey:NSForegroundColorAttributeName];
    }
    
    if (para != nil) {
        [attributes setObject:para forKey:NSParagraphStyleAttributeName];
    }
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    if (self.errorTitle) {
        NSRange range = [formatted rangeOfString:self.errorTitle];
        
        para = [para mutableCopy];
        para.lineHeightMultiple = 1.2f;
        
        attributes = [NSMutableDictionary new];
        
        font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        
        if (font != nil) {
            [attributes setObject:font forKey:NSFontAttributeName];
        }
        
        if (theme.titleColor != nil) {
            [attributes setObject:theme.titleColor forKey:NSForegroundColorAttributeName];
        }
        
        if (para != nil) {
            [attributes setObject:para forKey:NSParagraphStyleAttributeName];
        }
        
        [attrs addAttributes:attributes range:range];
    }
    
    self.errorLabel.attributedText = attrs;
    self.errorLabel.preferredMaxLayoutWidth = self.tableView.readableContentGuide.layoutFrame.size.width;
    [self.errorLabel sizeToFit];
    
}

#pragma mark - Getters

- (UINotificationFeedbackGenerator *)notificationGenerator {
    if (_notificationGenerator == nil) {
        _notificationGenerator = [[UINotificationFeedbackGenerator alloc] init];
        [_notificationGenerator prepare];
    }
    
    return _notificationGenerator;
}

- (UIActivityIndicatorView *)loaderView {
    
    if (_loaderView == nil) {
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleMedium;
        
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

#pragma mark - Actions

- (void)didTapClose:(UIBarButtonItem *)sender {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didTapClose:sender];
        });
        
        return;
    }
    
    self.cancelButton.enabled = NO;
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
//    if (self.selected != NSNotFound) {
//        Feed *feed = [self.DS.data safeObjectAtIndex:self.selected];
//        
//        if (feed == nil) {
//            self.selected = NSNotFound;
//            return;
//        }
//        
//        NSString *path = feed.url;
//        
//        NSURL *URL = [NSURL URLWithString:path];
//        
//        weakify(self);
//        
//        [MyFeedsManager addFeed:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//            
//            strongify(self);
//            
//            if ([responseObject isKindOfClass:Feed.class]) {
//                ArticlesManager.shared.feeds = [ArticlesManager.shared.feeds arrayByAddingObject:responseObject];
//                
//                weakify(self);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    strongify(self);
//                    [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
//                    [self.notificationGenerator prepare];
//                });
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    self.selected = NSNotFound;
//                    [self didTapClose:nil];
//                });
//                
//                return;
//            }
//            
//            NSLog(@"Unhandled response object %@ for status code: %@", responseObject, @(response.statusCode));
//            
//            asyncMain(^{
//                self.cancelButton.enabled = YES;
//            });
//            
//        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//            
//            strongify(self);
//            
//            if (error.code == 304) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    
//                    self.selected = NSNotFound;
//                    [self didTapClose:nil];
//                    
//                });
//                return;
//            }
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
//                [self.notificationGenerator prepare];
//            });
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.cancelButton.enabled = YES;
//            });
//            
//            [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription];
//            
//        }];
//        
//        return;
//    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
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
    
    UIKeyboardType existingKeyboardType = self.searchBar.keyboardType;
    
    if (selectedScope == 0) {
        self.searchBar.keyboardType = UIKeyboardTypeURL;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        // this prevents it from switching to the tab and then running the search
        self.searchBar.text = nil;
//        self.DS.data = @[];
//        self.DS.state = DZDatasourceDefault;
        
        if ([self.searchBar isFirstResponder] == NO) {
            [self.searchBar becomeFirstResponder];
        }
        
    }
    else {
        self.searchBar.keyboardType = UIKeyboardTypeDefault;
        self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
        
        [self searchBarTextDidEndEditing:self.searchBar];
    }
    
    if (self.searchBar.text == nil || [self.searchBar.text isBlank]) {
        [self setErrorLabelForDefaultState];
    }
    
    if (self.searchBar.keyboardType != existingKeyboardType) {
        [self.searchBar resignFirstResponder];
        [self.searchBar becomeFirstResponder];
    }
    
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
    if (searchBar.selectedScopeButtonIndex == 0) {
     
        [self searchByURL:searchBar.text];
        
        return;
    }
    
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
    
//    self.DS.data = @[];
//    self.DS.state = DZDatasourceLoading;
    
    [self loadNextPage];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - <ScrollLoading>

- (BOOL)isLoadingNext {
    return NO;
//    return self.DS.state == DZDatasourceLoading;
}

- (BOOL)cantLoadNext {
    return YES;
//    return self.loadedLast || self.DS.state == DZDatasourceError;
}

- (void)loadNextPage {
    
//    if (self.DS.state != DZDatasourceLoaded && self.page != 0) {
//        return;
//    }
//
//    if (self.query == nil) {
//        return;
//    }
//
//    self.DS.state = DZDatasourceLoading;
//
//    NSInteger page = self.page + 1;
//
//    self.networkTask = [MyFeedsManager search:self.query scope:self.searchBar.selectedScopeButtonIndex page:page success:^(NSArray <Feed *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        self.DS.state = DZDatasourceLoaded;
//
//        if (page == 1) {
//            self.DS.data = responseObject;
//        }
//        else {
//            NSArray *existing = self.DS.data;
//            NSArray *newSet = [existing arrayByAddingObjectsFromArray:responseObject];
//
//            self.DS.data = newSet;
//        }
//
//        self.loadedLast = responseObject.count < 20;
//
//        self.page = page;
//
//        NSLogDebug(@"%ld search results", responseObject.count);
//
//    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//        self.DS.state = DZDatasourceError;
//
//        if (page == 1) {
//            self.errorTitle = @"Error Loading Results";
//            self.errorBody = error.localizedDescription;
//        }
//        else {
//            // Do nothing
//            NSLog(@"Error loading search query: %@", error);
//        }
//
//    }];
    
}

#pragma mark -

- (void)searchByURL:(NSString *)text {
    
    if (text == nil || [text isBlank]) {
        return;
    }
    
    self.searchBar.userInteractionEnabled = NO;
    self.cancelButton.enabled = NO;
    
    NSURL *url = [NSURL URLWithString:[text stringByStrippingWhitespace]];
    
    if (!url) {
        [AlertManager showGenericAlertWithTitle:@"Incorrect URL" message:@"This is not a fully qualified URL. Please check the text you have entered."];
        
        return;
    }
    
    if ([url.absoluteString containsString:@"youtube.com"] == YES && [url.absoluteString containsString:@"videos.xml"] == NO) {
        
        [MyFeedsManager _checkYoutubeFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [self searchByURL:responseObject];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:@"An error occurred when trying to fetch the Youtube URL."];
            
        }];
    
        return;
        
    }
    
//    self.DS.state = DZDatasourceLoading;
    
    weakify(self);
    
    [MyFeedsManager addFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSInteger status = response.statusCode;
        
        strongify(self);
        
//        [MyAppDelegate _dismissAddingFeedDialog];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchBar.userInteractionEnabled = YES;
            self.cancelButton.enabled = YES;
        });
        
        if (status == 300) {
            // multiple options
            NSArray <Feed *> *feeds = [[responseObject rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                
                return [Feed instanceFromDictionary:obj];
                
            }] rz_filter:^BOOL(Feed * obj, NSUInteger idx, NSArray *array) {
                return obj.url && ([obj.url containsString:@"wp-json"] == NO);
            }];
            
//            self.DS.data = feeds;
//            self.DS.state = DZDatasourceLoaded;
            
            weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
                [self.notificationGenerator prepare];
            });
            
            return;
        }
        else if (responseObject && [responseObject isKindOfClass:Feed.class]) {
            ArticlesManager.shared.feeds = [ArticlesManager.shared.feeds arrayByAddingObject:responseObject];
            
            weakify(self);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [self.notificationGenerator prepare];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                
                self.selected = NSNotFound;
                [self didTapClose:nil];
            });
            return;
        }
        
        NSLog(@"Unhandled response object %@ for status code: %@", responseObject, @(response.statusCode));
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
//        [MyAppDelegate _dismissAddingFeedDialog];
        
//        self.DS.state = DZDatasourceError;
        
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
            [self.notificationGenerator prepare];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.searchBar.userInteractionEnabled = YES;
            self.cancelButton.enabled = YES;
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSString * title = @"Something went Wrong";
            
            if ([error.localizedDescription containsString:@"already exists"]) {
                title = @"Existing Feed";
            }
            
            [AlertManager showGenericAlertWithTitle:title message:error.localizedDescription];
        });
        
    }];
    
}

#pragma mark - <UISearchControllerDelegate>

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {}

@end
