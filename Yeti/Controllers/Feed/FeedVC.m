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
#import "AuthorVC.h"

#import "YetiConstants.h"

#import "FeedsManager.h"

#import <DZKit/EFNavController.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

#import "FeedSearchResults.h"
#import "ArticleProvider.h"

#import "FeedHeaderView.h"
#import <UserNotifications/UserNotifications.h>

#import "YetiThemeKit.h"
#import "TableHeader.h" 

@interface FeedVC () <DZDatasource, ArticleProvider, FeedHeaderViewDelegate, UIViewControllerRestoration, UITableViewDragDelegate> {
    UIImageView *_barImageView;
    BOOL _ignoreLoadScroll;
}

@property (nonatomic, weak) FeedHeaderView *headerView;
@property (nonatomic, weak) UIView *hairlineView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@end

@implementation FeedVC

- (instancetype)initWithFeed:(Feed *)feed {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.feed = feed;
        _canLoadNext = YES;
        _page = 0;
        
        self.restorationIdentifier = formattedString(@"%@-%@", NSStringFromClass(self.class), feed.feedID);
        self.restorationClass = self.class;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.feed displayTitle];
    self.tableView.restorationIdentifier = self.restorationIdentifier;
    
    self.tableView.dragDelegate = self;
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    if (self.feed != nil && self.feed.articles != nil && self.feed.articles.count > 0) {
        self.DS.data = self.feed.articles;
    }
    
    self.DS.addAnimation = UITableViewRowAnimationLeft;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    _page = 0;
    _canLoadNext = YES;
    _loadingNext = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCell.class) bundle:nil] forCellReuseIdentifier:kArticleCell];
    
    self.tableView.tableFooterView = [UIView new];
    
    [self setupNavBar];
    
    if ([self respondsToSelector:@selector(author)] || (self.feed.authors && self.feed.authors.count > 1)) {
        [self setupHeaderView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.DS.data = @[];
    _page = 0;
    _canLoadNext = YES;
    
    if (self.feed) {
        self.feed.articles = @[];
    }
    
    [AlertManager showGenericAlertWithTitle:@"Memory Warning" message:@"The app received a memory warning and to prevent unexpected crashes, it had to clear articles from the current feed. Please reload the feed to continue viewing."];
}

- (void)dealloc {
    if (self.feed) {
        self.feed.articles = @[];
    }
}

#pragma mark - Appearance

- (BOOL)definesPresentationContext
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (_page == 0) {
        [self loadNextPage];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception when unregistering: %@", exc);
    }
}

- (void)_setToolbarHidden {
    self.navigationController.toolbarHidden = YES;
}

#pragma mark - Setups

- (void)setupNavBar {
    
    UIButton *allReadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [allReadButton setImage:[UIImage imageNamed:@"done_all"] forState:UIControlStateNormal];
    [allReadButton sizeToFit];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAllRead:)];
    [allReadButton addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressOnAllRead:)];
    [allReadButton addGestureRecognizer:longPress];
    
    [longPress requireGestureRecognizerToFail:tap];
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithCustomView:allReadButton];
    allRead.accessibilityValue = @"Mark Read";
    allRead.accessibilityHint = @"Mark all current articles as read. Long Tap to Mark all backdated articles as read.";
    allRead.width = 32.f;
    
    if (self.isExploring) {
        // check if the user is subscribed to this feed
        Feed *existing = [MyFeedsManager feedForID:self.feed.feedID];
        if (!existing) {
            // allow subscription
            UIBarButtonItem *subscribe = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStyleDone target:self action:@selector(subscribeToFeed:)];
            subscribe.accessibilityValue = @"Subscribe to this feed";
            self.navigationItem.rightBarButtonItem = subscribe;
        }
    }
    else {
        
        // sorting button
        YetiSortOption option = SharedPrefs.sortingOption;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL isUnread = NSSelectorFromString(@"isUnread");
        
        if ([self respondsToSelector:isUnread] && (BOOL)[self performSelector:isUnread] == YES) {
            
            // when the active option is either of these two, we don't need
            // to do anything extra
            if (option != YTSortUnreadAsc && option != YTSortUnreadDesc) {
                
                // map it to whatever the selected option is
                if (option == YTSortAllAsc) {
                    option = YTSortUnreadAsc;
                }
                else if (option == YTSortAllDesc) {
                    option = YTSortUnreadDesc;
                }
                
            }
            
        }
#pragma clang diagnostic pop
        
        UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:[SortImageProvider imageForSortingOption:option] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSortOptions:)];
        sorting.width = 32.f;
        
        if (!(self.feed.hubSubscribed && self.feed.hub)) {
            NSMutableArray *buttons = @[allRead].mutableCopy;
            
            if ([self showsSortingButton]) {
                [buttons addObject:sorting];
            }
            
            self.navigationItem.rightBarButtonItems = buttons;
        }
        else {
            // push notifications are possible
            NSString *imageString = self.feed.isSubscribed ? @"notifications_on" : @"notifications_off";
            
            UIBarButtonItem *notifications = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageString] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNotifications:)];
            notifications.accessibilityValue = self.feed.isSubscribed ? @"Subscribe" : @"Unsubscribe";
            notifications.accessibilityHint = self.feed.isSubscribed ? @"Unsubscribe from notifications" : @"Subscribe to notifications";
            notifications.width = 32.f;
            
            NSMutableArray *buttons = @[allRead, notifications].mutableCopy;
            
            if ([self showsSortingButton]) {
                [buttons addObject:sorting];
            }
            
            self.navigationItem.rightBarButtonItems = buttons;
        }
        
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    // Search Controller setup
    {
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search Articles";
        searchController.searchBar.accessibilityValue = @"Search loaded articles";
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchController.searchBar.restorationIdentifier = [self.restorationIdentifier stringByAppendingString:@"-searchbar"];
        searchController.restorationIdentifier = [self.restorationIdentifier stringByAppendingString:@"-searchController"];
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.navigationItem.searchController = searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, searchController.searchBar.bounds.size.height, searchController.searchBar.bounds.size.width, height)];
        hairline.backgroundColor = theme.cellColor;
        hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        
        [searchController.searchBar addSubview:hairline];
        self.hairlineView = hairline;
    }
    
}

- (void)setupHeaderView
{
    
    if (_headerView)
        return;
    
    FeedHeaderView *headerView = [[FeedHeaderView alloc] initWithNib];
    headerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.f);
    
    [headerView configure:self.feed];
    headerView.delegate = self;
    
    self.tableView.tableHeaderView = headerView;
    
    _headerView = headerView;
}

#pragma mark - Getters

- (BOOL)showsSortingButton {
    return YES;
}

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
    
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        Theme *theme = [YTThemeKit theme];
        
        UIActivityIndicatorViewStyle style = theme.isDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [view sizeToFit];
        
        [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
        
        view.hidesWhenStopped = YES;
        
        _activityIndicatorView = view;
    }
    
    return _activityIndicatorView;
}

#pragma mark - Setters

- (void)setLoadOnReady:(NSNumber *)loadOnReady
{
    if (loadOnReady == nil) {
        _loadOnReady = loadOnReady;
        return;
    }
    
    if (self.DS == nil || self.DS.data == nil || self.DS.data.count == 0) {
        weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            [self setLoadOnReady:loadOnReady];
        });
        
        return;
    }
    
    _loadOnReady = loadOnReady;
    
    if (loadOnReady && [[self navigationController] visibleViewController] == self) {
        // we are visible
        [self loadArticle];
    }
}

#pragma mark - Actions

- (void)loadArticle {
    
    if (self.loadOnReady == nil)
        return;
    
    if (!self.DS.data.count)
        return;
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)[self.DS data] enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.identifier isEqualToNumber:self.loadOnReady]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return;
    
    self.loadOnReady = nil;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        
    });
    
}

- (void)_markVisibleRowsRead {
    
    if ([self.class isKindOfClass:NSClassFromString(@"CustomFeedVC")] == YES) {
        return;
    }
    
    NSArray <NSIndexPath *> *indices = [self.tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *indexPath in indices) { @autoreleasepool {
       
        ArticleCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        FeedItem *item = [self.DS objectAtIndexPath:indexPath];
        
        if (cell.markerView.image != nil && (item != nil && item.isBookmarked == NO)) {
            cell.markerView.image = nil;
        }
        
    } }
    
}

- (void)didTapAllRead:(id)sender {
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        NSArray <FeedItem *> *unread = [(NSArray <FeedItem *> *)self.DS.data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return !obj.isRead;
        }];
        
        [MyFeedsManager articles:unread markAsRead:YES];
        
        weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            if (self && [self tableView]) {
                [self _markVisibleRowsRead];
                [self _didFinishAllReadActionSuccessfully];
            }
        });
    };
    
    if (showPrompt) {
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Mark all Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            markReadInline();
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentAllReadController:avc fromSender:sender];
    }
    else {
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        
        markReadInline();
    }
    
}

- (void)didLongPressOnAllRead:(id)sender {
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        [MyFeedsManager markFeedRead:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self && [self tableView]) {
                    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
                        self.DS.data = @[];
                    }
                    else {
                        [self _markVisibleRowsRead];
                        [self _didFinishAllReadActionSuccessfully];
                    }
                }
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Marking all Read" message:error.localizedDescription];
            
        }];
    };
    
    if (showPrompt) {
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark all articles as read including articles not currently loaded?" preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Mark all Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            markReadInline();
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular){
            
            UIPopoverPresentationController *pvc = avc.popoverPresentationController;
            pvc.barButtonItem = sender;
            
        }
        
        [self presentAllReadController:avc fromSender:sender];
    }
    else {
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        markReadInline();
    }
}

- (void)_didFinishAllReadActionSuccessfully {
    
}

- (void)didTapNotifications:(UIBarButtonItem *)sender {
    
    weakify(self);
    
    sender.enabled = NO;
    
    if (self.feed.isSubscribed) {
        // unsubsribe
        
        [MyFeedsManager unsubscribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            self.feed.subscribed = NO;
            
            asyncMain(^{
                sender.enabled = YES;
                sender.image = [UIImage imageNamed:@"notifications_off"];
                sender.accessibilityValue = @"Subscribe to notifications";
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            asyncMain(^{
                sender.enabled = YES;
            });
           
            [AlertManager showGenericAlertWithTitle:@"Unsubscribe Failed" message:error.localizedDescription];
            
        }];
        
        return;
    }
    
    if (!MyFeedsManager.pushToken) {
        // register for push notifications first.
        
        if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            
            MyFeedsManager.subsribeAfterPushEnabled = self.feed;
            
            weakify(self);
            
            asyncMain(^{
                sender.enabled = YES;
            });
            
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
                
                if (error) {
                    DDLogError(@"Error authorizing for push notifications: %@",error);
                    return;
                }
                
                if (granted) {
                    strongify(self);
                    
                    MyFeedsManager.keychain[kIsSubscribingToPushNotifications] = [@YES stringValue];
                    
                    asyncMain(^{
                        [UIApplication.sharedApplication registerForRemoteNotifications];
                    });
                    
                    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(subscribedToFeed:) name:SubscribedToFeed object:nil];
                }
                
            }];
            
            return;
        }
        else {
            
            if (MyFeedsManager.keychain[kIsSubscribingToPushNotifications] == nil) {
                MyFeedsManager.keychain[kIsSubscribingToPushNotifications] = [@YES stringValue];
            }
            
            asyncMain(^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
            });
        }
    }
    
    // add subscription
    [MyFeedsManager subsribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.feed.subscribed = YES;
        
        asyncMain(^{
            sender.enabled = YES;
            sender.image = [UIImage imageNamed:@"notifications_on"];
            sender.accessibilityValue = @"Unsubscribe from notifications";
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        asyncMain(^{
            sender.enabled = YES;
        });
        
        [AlertManager showGenericAlertWithTitle:@"Subscribe Failed" message:error.localizedDescription];
    }];
    
}

- (void)subscribeToFeed:(UIBarButtonItem *)sender {
    
    sender.enabled = NO;
    
    weakify(self);
    
    [MyFeedsManager addFeedByID:self.feed.feedID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <Feed *> *feeds = MyFeedsManager.feeds;
        feeds = [feeds arrayByAddingObject:responseObject];
        
        MyFeedsManager.feeds = feeds;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            self.navigationItem.rightBarButtonItem = nil;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
        });
        
        [AlertManager showGenericAlertWithTitle:@"Error Subscribing" message:error.localizedDescription];
        
    }];
    
}

// this is push notifications
- (void)subscribedToFeed:(NSNotification *)note {
    
    Feed *obj = note.object;
    
    if (!obj)
        return;
    
    if (![obj.feedID isEqualToNumber:self.feed.feedID]) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:SubscribedToFeed object:nil];
    
    weakify(self);
    
    asyncMain(^{
       
        strongify(self);
        
        self.feed.subscribed = YES;
        
        UIBarButtonItem *sender = [self.navigationItem.rightBarButtonItems lastObject];
        
        sender.image = [UIImage imageNamed:@"notifications_on"];
        sender.accessibilityValue = @"Unsubscribe from notifications";
        
    });
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"All - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllDesc];
        
        [self setSortingOption:YTSortAllDesc];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"All - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllAsc];
        
        [self setSortingOption:YTSortAllAsc];
        
    }];
    
    UIAlertAction *unreadDesc = [UIAlertAction actionWithTitle:@"Unread - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc];
        
        [self setSortingOption:YTSortUnreadDesc];
        
    }];
    
    UIAlertAction *unreadAsc = [UIAlertAction actionWithTitle:@"Unread - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc];
        
        [self setSortingOption:YTSortUnreadAsc];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        [allDesc setValue:[SortImageProvider imageForSortingOption:YTSortAllDesc] forKeyPath:@"image"];
        [allAsc setValue:[SortImageProvider imageForSortingOption:YTSortAllAsc] forKeyPath:@"image"];
        [unreadDesc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadDesc] forKeyPath:@"image"];
        [unreadAsc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadAsc] forKeyPath:@"image"];
    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    [avc addAction:unreadDesc];
    [avc addAction:unreadAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

#pragma mark -

- (void)setSortingOption:(YetiSortOption)option {
    
    [SharedPrefs setValue:option forKey:propSel(sortingOption)];
    
    self->_canLoadNext = YES;
    self.loadingNext = NO;
    
    self->_page = 0;
    [self.DS resetData];
    
    [self loadNextPage];
}

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender {
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular){
        
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        
        if ([sender isKindOfClass:UIGestureRecognizer.class]) {
            UIView *view = [(UITapGestureRecognizer *)sender view];
            pvc.sourceView = self.view;
            CGRect frame = [view convertRect:view.frame toView:self.view];
            
            frame.origin.x -= [avc preferredContentSize].width;
            pvc.sourceRect = frame;
        }
        else {
            pvc.barButtonItem = sender;
        }
        
    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

#pragma mark - Table view data source

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available from %@", self.feed.title);
}

- (UIView *)viewForEmptyDataset {
    
    // since the Datasource is asking for this view
    // it will be presenting it.
    if ((_canLoadNext == YES || _loadingNext == YES) && _page == 0) {
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
        
        return self.activityIndicatorView;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.backgroundColor = theme.cellColor;
    label.opaque = YES;
    
    NSString *title = @"No Articles";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                 NSForegroundColorAttributeName: theme.subtitleColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                   NSForegroundColorAttributeName: theme.titleColor,
                   NSParagraphStyleAttributeName: para
                   };
    
    NSRange range = [formatted rangeOfString:title];
    if (range.location != NSNotFound) {
        [attrs addAttributes:attributes range:range];
    }
    
    label.attributedText = attrs;
    [label sizeToFit];
    
    return label;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (self.headerView != nil) {
        TableHeader *header = [[TableHeader alloc] initWithNib];
        header.label.text = @"All Articles".uppercaseString;
        
        return header;
    }
    
    return [UIView new];
    
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section {
    
    if (self.headerView != nil) {
        return 52.f;
    }
    
    return 0.f;
    
}

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
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.view.backgroundColor = [(YetiTheme *)[YTThemeKit theme] backgroundColor];
        nav.restorationIdentifier = @"ArticleDetailNav";
        
        [self.splitViewController showDetailViewController:nav sender:self];
        // hide the primary controller
        UIBarButtonItem *item = [self.splitViewController displayModeButtonItem];
        [UIApplication.sharedApplication sendAction:item.action to:item.target from:nil forEvent:nil];
    }
    else {
        [self.navigationController pushViewController:vc animated:YES];
    }
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")] == NO) {
    
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            ArticleCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (cell && cell.markerView.image != nil && item.isBookmarked == NO) {
                cell.markerView.image = nil;
            }
            
        });
        
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    NSString *title = item.isRead ? @"Mark as Unread" : @"Mark as Read";
    
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:title handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MyFeedsManager article:item markAsRead:!NO];
            
            item.read = !item.isRead;
            
            completionHandler(YES);
        });
        
    }];
    
    action.backgroundColor = [UIColor colorWithRed:0/255.f green:122/255.f blue:255/255.f alpha:1.f];
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[action]];
    config.performsFirstActionWithFullSwipe = YES;
    
    return config;
    
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    weakify(self);
    
    UIContextualAction *action = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Open in Browser" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        strongify(self);
        
        FeedItem * item = [self.DS objectAtIndexPath:indexPath];
        
        NSURL *URL = formattedURL(@"yeti://external?link=%@", [item articleURL]);
        
        asyncMain(^{
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:completionHandler];
        });
        
        
    }];
    
    action.backgroundColor = self.view.tintColor;
    
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[action]];
    config.performsFirstActionWithFullSwipe = YES;
    
    return config;
}

#pragma mark - <ScrollLoading>

- (void)loadNextPage
{
    
    if (self.loadingNext && _page > 0)
        return;
    
    if (self->_ignoreLoadScroll)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    NSInteger page = self->_page + 1;
    
    YetiSortOption sorting = SharedPrefs.sortingOption;
    
    [MyFeedsManager getFeed:self.feed sorting:sorting page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self.loadingNext = NO;
        
        if (!responseObject.count) {
            self->_canLoadNext = NO;
        }
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            NSArray *articles = page == 1 ? @[] : (self.feed.articles ?: @[]);
            articles = [articles arrayByAddingObjectsFromArray:responseObject];
            self.feed.articles = articles;
            self->_ignoreLoadScroll = YES;
            
            @try {
                self.DS.data = self.feed.articles;
            }
            @catch (NSException *exc) {
                DDLogWarn(@"Exception updating feed articles: %@", exc);
            }
        });
        
        self->_page = page;
        
        if ([self loadOnReady] != nil) {
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                [self loadArticle];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if (self->_ignoreLoadScroll) {
                self->_ignoreLoadScroll = NO;
            }
        });
        
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

- (void)willChangeArticle {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
    });
}

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
        
        [self willChangeArticle];
        
        return [((NSArray <FeedItem *> *)self.DS.data) safeObjectAtIndex:index];
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
        
        [self willChangeArticle];
        
        return [((NSArray <FeedItem *> *)self.DS.data) safeObjectAtIndex:index];
    }
    
    return nil;
}

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read
{
    
    if (!article)
        return;
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
        return;
    }
    
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:article];
    
    if (index == NSNotFound)
        return;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.read = read;
        }
        
        FeedItem *articleInDS = [(NSArray <FeedItem *> *)self.DS.data safeObjectAtIndex:index];
        
        if (articleInDS) {
            articleInDS.read = read;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSArray <NSIndexPath *> * visible = self.tableView.indexPathsForVisibleRows;
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.row == index) {
                    isVisible = YES;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                // only change when not bookmarked. If bookmarked, continue showing the bookmark icon
                if (cell != nil && article.isBookmarked == NO) {
                    if (read == YES) {
                        cell.markerView.image = nil;
                    }
                    else {
                        cell.markerView.image = [UIImage imageNamed:@"munread"];
                    }
                }
            }
        }
    });
}

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked {
    
    if (!article)
        return;
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
        return;
    }
    
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:article];
    
    if (index == NSNotFound)
        return;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.bookmarked = bookmarked;
        }
        
        FeedItem *articleInDS = [(NSArray <FeedItem *> *)self.DS.data safeObjectAtIndex:index];
        
        if (articleInDS) {
            articleInDS.bookmarked = bookmarked;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSArray <NSIndexPath *> * visible = self.tableView.indexPathsForVisibleRows;
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.row == index) {
                    isVisible = YES;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if (cell != nil) {
                    if (bookmarked == NO) {
                        cell.markerView.image = nil;
                    }
                    else {
                        cell.markerView.image = [UIImage imageNamed:@"mbookmark"];
                    }
                }
            }
        }
    });
    
}

- (void)didChangeToArticle:(FeedItem *)item
{
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didChangeToArticle:item];
        });
        
        return;
    }
    
    __block NSUInteger index = NSNotFound;
    
    [self.DS.data enumerateObjectsUsingBlock:^(FeedItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToNumber:item.identifier]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index == NSNotFound)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    if (self.class != NSClassFromString(@"CustomFeedVC") && !item.isRead) {
        [self userMarkedArticle:item read:YES];
    }
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        [self scrollViewDidEndDecelerating:self.tableView];
    });
}

#pragma mark - <FeedHeaderViewDelegate>

- (void)didTapAuthor:(Author *)author
{
    AuthorVC *vc = [[AuthorVC alloc] initWithFeed:self.feed];
    vc.author = author;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - State Restoration

NSString * const kFeedData = @"FeedData";
NSString * const kCurrentPage = @"FeedsLoadedPage";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Feed *feed = [coder decodeObjectForKey:kFeedData];
    
    if (feed) {
        FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
        return vc;
    }
    
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.feed forKey:kFeedData];
    [coder encodeInteger:_page forKey:kCurrentPage];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
    Feed *feed = [coder decodeObjectForKey:kFeedData];
    
    if (feed) {
        self.feed = feed;
        self.DS.data = self.feed.articles;
        _page = [coder decodeIntegerForKey:kCurrentPage];
    }
    
}

#pragma mark - <UITableViewDragDelegate>

- (UIDragItem *)dragItemForIndexPath:(NSIndexPath *)indexPath {
    FeedItem *article = [self.DS objectAtIndexPath:indexPath];
    
    if (article == nil) {
        return nil;
    }
    
    NSString *url = article.articleURL;
    
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:url];
    
    UIDragItem *item = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    
    return item;
}

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView itemsForBeginningDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath
{
    
    UIDragItem *item = [self dragItemForIndexPath:indexPath];
    
    if (item) {
        return @[item];
    }
    
    return @[];
    
}

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView itemsForAddingToDragSession:(id<UIDragSession>)session atIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point
{
    
    UIDragItem *item = [self dragItemForIndexPath:indexPath];
    
    if (item) {
        return @[item];
    }
    
    return @[];
    
}

@end
