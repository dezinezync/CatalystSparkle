//
//  ArticleVC+Toolbar.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/AlertManager.h>

#import "AppDelegate.h"

#import "Paragraph.h"
#import "Elytra-Swift.h"

#import "EmptyVC.h"
#import "CustomizeVC.h"

#import "YetiConstants.h"
#import "UITextField+CursorPosition.h"

#import <DZAppdelegate/UIApplication+KeyWindow.h>

@implementation ArticleVC (Toolbar)

- (NSArray <UIBarButtonItem *> *)leftBarButtonItems {
    
    if (self.noAuth) {
        return @[];
    }
    
    UIImage * readImage = [UIImage systemImageNamed:@"smallcircle.fill.circle"],
            * bookmarkImage = [UIImage systemImageNamed:(self.item.bookmarked ? @"bookmark.fill" : @"bookmark")],
            * searchImage = [UIImage systemImageNamed:@"magnifyingglass"];

    UIBarButtonItem *read = [[UIBarButtonItem alloc] initWithImage:readImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapRead:)];
    read.accessibilityValue = self.item.read ? @"Mark article unread" : @"Mark article read";
    read.accessibilityLabel = self.item.read ? @"Mark Unread" : @"Mark Read";
    
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc] initWithImage:bookmarkImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapBookmark:)];
    
    bookmark.accessibilityValue = self.item.bookmarked ? @"Remove from bookmarks" : @"Bookmark article";
    bookmark.accessibilityLabel = self.item.bookmarked ? @"Unbookmark" : @"Bookmark";
    
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithImage:searchImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapSearch)];
    
    search.accessibilityValue = @"Search in article";
    search.accessibilityLabel = @"Search";

    // these are assigned in reverse order
    NSMutableArray *lefItems = @[search].mutableCopy;
    
    if (PrefsManager.sharedInstance.hideBookmarks == NO) {
        [lefItems addObject:bookmark];
    }
    
    [lefItems addObject:read];
    
    return lefItems;
    
}

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    if (self.noAuth) {
        return @[];
    }
    
    if (self.providerDelegate == nil) {
        return @[];
    }
    
    UIBarButtonItem *prevArticle = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapPreviousArticle:)];
    prevArticle.accessibilityValue = @"Previous article";
    
    UIBarButtonItem *nextArticle = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.down"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNextArticle:)];
    nextArticle.accessibilityValue = @"Next article";
    
    BOOL next = [self.providerDelegate hasPreviousArticleForArticle:self.item];
    BOOL previous = [self.providerDelegate hasNextArticleForArticle:self.item];
    
    prevArticle.enabled = previous;
    nextArticle.enabled = next;
    
    if (self.helperView != nil) {
        self.helperView.startOfArticle.enabled = NO;
        self.helperView.endOfArticle.enabled = YES;
    }
    
    if (PrefsManager.sharedInstance.useToolbar == YES) {
        _nextButtonItem = nextArticle;
        _prevButtonItem = prevArticle;
    }
    
    return @[nextArticle, prevArticle];
    
}

- (NSArray <UIBarButtonItem *> *)commonNavBarItems {
    
    if (self.noAuth) {
        return @[];
    }
    
    UIImage * shareImage = [UIImage systemImageNamed:@"square.and.arrow.up"],
            * browserImage = [UIImage systemImageNamed:@"safari"],
            * customizeImage = [UIImage systemImageNamed:@"doc.richtext"];
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:shareImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapShare:)];
    
    share.accessibilityValue = @"Share article";
    share.accessibilityLabel = @"Share";
    share.title = share.accessibilityLabel;
    
    UIBarButtonItem *browser = [[UIBarButtonItem alloc] initWithImage:browserImage style:UIBarButtonItemStylePlain target:self action:@selector(openInBrowser)];
    browser.accessibilityValue = @"Open the article in the browser";
    browser.accessibilityLabel = @"Browser";
    browser.title = browser.accessibilityLabel;
    
    UIBarButtonItem *customize = [[UIBarButtonItem alloc] initWithImage:customizeImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapCustomize:)];
    customize.accessibilityValue = @"Customize the Article Reader Interface";
    customize.accessibilityLabel = @"Customize";
    customize.title = customize.accessibilityLabel;
    
    if (self.isExploring) {
        return @[share, browser];
    }
    
    return @[share, browser, customize];
    
}

- (NSArray <UIBarButtonItem *> *)toolbarItems {
    
    self.navigationItem.rightBarButtonItems = self.commonNavBarItems;
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        return nil;
    }
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 24.f;
    
    NSArray *left = [[[self.leftBarButtonItems rz_map:^id(UIBarButtonItem *obj, NSUInteger idx, NSArray *array) {
        
        if (idx == 0) {
            return obj;
        }
        
        return @[flex, obj];
        
    }] rz_flatten] arrayByAddingObject:flex];
    
    NSArray *right = [[self.rightBarButtonItems rz_map:^id(UIBarButtonItem *obj, NSUInteger idx, NSArray *array) {
        
        if (idx == 0) {
            return obj;
        }
        
        return @[flex, obj];
        
    }] rz_flatten];
    
    return [left arrayByAddingObjectsFromArray:right];
}


- (void)setupToolbar:(UITraitCollection *)newCollection {
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        NSArray <UIBarButtonItem *> *items = [self.commonNavBarItems arrayByAddingObjectsFromArray:self.leftBarButtonItems];
        self.navigationItem.rightBarButtonItems = items;
        self.navigationController.toolbarHidden = YES;
        
    }
    else {
        self.navigationController.toolbarHidden = NO;
    }
    
    if (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular && self.splitViewController != nil) {
        
        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapClose)];
        
        self.navigationItem.leftBarButtonItem = close;
        
    }
    else {
        self.navigationItem.leftBarButtonItems = nil;
    }
}

#pragma mark - Actions

- (void)didTapClose {
    
    if (self.searchBar.isFirstResponder) {
        
        self.searchBar.searchTextField.cursorPosition = 0;
        
        return;
    }
    
    [self.coordinator showEmptyVC];
    
    FeedVC *top = self.coordinator.feedVC;

    if (top != nil && ([top isKindOfClass:FeedVC.class] || [top.class isSubclassOfClass:FeedVC.class])) {
        NSArray <NSIndexPath *> *selectedItems = [top.tableView indexPathsForSelectedRows];

        NSIndexPath *selected = selectedItems.count ? [selectedItems firstObject] : nil;

        if (selected != nil) {
            [top.tableView deselectRowAtIndexPath:selected animated:YES];
        }
    }
}

- (void)didTapShare:(UIBarButtonItem *)sender {
    
    if (!self.item)
        return;
    
    NSString *title = self.item.title;
    NSURL *URL = formattedURL(@"%@", self.item.url);
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, @" ", URL] applicationActivities:nil];
    
    if (sender && [sender isKindOfClass:UIBarButtonItem.class]) {
    
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.barButtonItem = sender;
        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        
    }
#if TARGET_OS_MACCATALYST
    else if (sender && [sender isKindOfClass:NSToolbarItem.class]) {
      
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.sourceView = self.view;
        pvc.sourceRect = CGRectMake(self.view.bounds.size.width - 200.f, 36.f, self.view.bounds.size.width, 1);
//        pvc.barButtonItem = (UIBarButtonItem *)sender;
//        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        
    }
#endif
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

- (void)didTapBookmark:(UIBarButtonItem *)button {
    
    BOOL isButton = button && [button respondsToSelector:@selector(setEnabled:)];
    
    if (isButton) {
        
        button.enabled = NO;
        
    }
    
    weakify(self);
    
    [self.providerDelegate userMarkedArticle:self.item bookmarked:!(self.item.bookmarked) completion:^(BOOL completed) {
        
        if (isButton) {
            
            if (completed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    UIImage *image = self.item.bookmarked ? [UIImage systemImageNamed:@"bookmark.fill"] : [UIImage systemImageNamed:@"bookmark"];
                    
                    [button setImage:image];
                    
                    strongify(self);
                    
                    [[self notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
                    [[self notificationGenerator] prepare];
                    
                });
                
            }
            
            button.enabled = YES;
            
        }
        
    }];
    
}

- (void)didTapRead:(UIBarButtonItem *)button {
    
    BOOL isButton = button && [button respondsToSelector:@selector(setEnabled:)];
    
    if (isButton) {
        button.enabled = NO;
    }
    
    weakify(self);
    
    BOOL read = !self.item.read;
    
    [self.providerDelegate userMarkedArticle:self.item read:read completion:^(BOOL completed) {
        
        if (isButton) {
            
            if (completed) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    button.image = self.item.read ? [UIImage systemImageNamed:@"smallcircle.fill.circle"] : [UIImage systemImageNamed:@"largecircle.fill.circle"];
                    
                    strongify(self);
                    
                    [[self notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
                    [[self notificationGenerator] prepare];
                    
                });
                
            }
            
            button.enabled = YES;
            
        }
        
    }];
    
}

- (void)openInBrowser {
    
    if (self.searchBar.isFirstResponder) {
        
        self.searchBar.searchTextField.cursorPosition = self.searchBar.text != nil ? self.searchBar.text.length : 0;
        
        return;
    }
    
    NSURL *URL = formattedURL(@"yeti://external?link=%@", self.item.url);
    
#if TARGET_OS_MACCATALYST
    if (self->_shiftPressedBeforeClickingURL) {
        
        URL = formattedURL(@"%@&shift=1", URL.absoluteString);
        
    }
#else
    
    Feed *feed = [MyFeedsManager feedFor:self.item.feedID];
    
    if (feed != nil) {
        
        FeedMeta *meta = [MyFeedsManager metadataForFeed:feed];
        
        if (meta) {
            
            URL = formattedURL(@"%@&ytreader=1", URL.absoluteString);
            
        }
        
    }
    
#endif
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    
}

- (void)didTapSearch
{
    
    if (_showSearchBar == YES) {
        [self didTapSearchDone];
        return;
    }
    
    [self becomeFirstResponder];
    
    _showSearchBar = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
#if TARGET_OS_MACCATALYST
        [self.view addSubview:self.searchView];
        
        UIEdgeInsets additional = self.additionalSafeAreaInsets;
        additional.top += 52.f;
        
        self.additionalSafeAreaInsets = additional;
        
        [self viewSafeAreaInsetsDidChange];
#else
        [self reloadInputViews];
#endif
        [self.view setNeedsLayout];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.searchBar becomeFirstResponder];
    });
}

- (void)didTapSearchDone
{
    
    _showSearchBar = NO;
    [self.searchBar resignFirstResponder];
    [self.searchBar setText:nil];
    
    _searchingRects = nil;
    [self removeSearchResultViewFromSuperview];
    
    [self.searchView removeFromSuperview];
    
#if TARGET_OS_MACCATALYST
    UIEdgeInsets additional = self.additionalSafeAreaInsets;
    additional.top -= 52.f;
    
    self.additionalSafeAreaInsets = additional;
    
    [self viewSafeAreaInsetsDidChange];
#endif
    
    [self reloadInputViews];
}

- (void)didTapSearchPrevious
{
    
    if (_searchHighlightingRect == nil) {
        return;
    }
    
    if (_searchCurrentIndex == 0) {
        // we are on the first possible result. This shouldn't be possible.
        self.searchPrevButton.enabled = NO;
        return;
    }
    
    NSValue *prevValue = _searchingRects[_searchCurrentIndex-1];
    
    weakify(self)
    
    if (prevValue) {
        _searchCurrentIndex--;
        
        [UIView animateWithDuration:0.2 animations:^{
            strongify(self);
            self->_searchHighlightingRect.frame = CGRectInset(prevValue.CGRectValue, -4.f, 0.f);
        }];
        
        [self scrollToRangeRect:prevValue];
    }
    
    if (_searchCurrentIndex == 0)
        self.searchPrevButton.enabled = NO;
    
    // if previous was tappable, next should be tappable now
    if (!self.searchNextButton.isEnabled)
        self.searchNextButton.enabled = YES;
    
    [self.feedbackGenerator selectionChanged];
    [self.feedbackGenerator prepare];
}

- (void)didTapSearchNext
{
    if (_searchHighlightingRect == nil) {
        return;
    }
    
    if (_searchCurrentIndex == (_searchingRects.count-1)) {
        // we are on the last result. This shouldn't be possible.
        self.searchNextButton.enabled = NO;
        return;
    }
    
    NSValue *nextValue = _searchingRects[_searchCurrentIndex+1];
    if (nextValue) {
        _searchCurrentIndex++;
        self->_searchHighlightingRect.frame = CGRectInset(nextValue.CGRectValue, -4.f, 0.f);
        [self scrollToRangeRect:nextValue];
    }
    
    if (_searchCurrentIndex == (_searchingRects.count - 1))
        self.searchNextButton.enabled = NO;
    
    // if next was tappable, previous should be tappable now
    if (!self.searchPrevButton.isEnabled)
        self.searchPrevButton.enabled = YES;
    
    [self.feedbackGenerator selectionChanged];
    [self.feedbackGenerator prepare];
}

- (void)keyboardFrameChanged:(NSNotification *)note
{
    _keyboardRect = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (_keyboardRect.origin.y >= [UIScreen mainScreen].bounds.size.height)
        _keyboardRect.size.height = 0.f;
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    UIEdgeInsets insets = [scrollView contentInset];
    
    insets.bottom = _keyboardRect.size.height;
    
    scrollView.contentInset = insets;
    scrollView.scrollIndicatorInsets = insets;
}

- (void)scrollToRangeRect:(NSValue *)value {
    
    if (!value)
        return;
    
    if (!NSThread.isMainThread) {
        
        [self performSelectorOnMainThread:@selector(scrollToRangeRect:) withObject:value waitUntilDone:NO];
        
        return;
    }
    
    UIScrollView *scrollView = (UIScrollView *)(self.stackView.superview);
    
    CGRect rect = value.CGRectValue;
    CGRect frame = rect;
    frame.origin.x += self.stackView.frame.origin.x;
    frame.origin.y += 12.f;
    
    weakify(self);
    
    CGRect scrollRect = rect;
    // since we reference the scrollRect from 0,0 (top, left) in iOS.
    scrollRect.origin.y -= scrollView.adjustedContentInset.top;
    
    if (!CGPointEqualToPoint(scrollRect.origin, scrollView.contentOffset)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [scrollView setContentOffset:CGPointMake(0.f, scrollRect.origin.y) animated:YES];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        self->_searchHighlightingRect.frame = CGRectInset(frame, -4.f, 0.f);
    });
}

- (void)didTapCustomize:(UIBarButtonItem *)sender {
    
    CustomizeVC *instance = [[CustomizeVC alloc] initWithStyle:UITableViewStyleGrouped];
    instance.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *pvc = instance.popoverPresentationController;
    
#if TARGET_OS_MACCATALYST
    if (sender && [sender isKindOfClass:NSToolbarItem.class]) {
      
        pvc.sourceView = self.view;
        pvc.sourceRect = CGRectMake(self.view.bounds.size.width - 60.f, 22.f, self.view.bounds.size.width, 1);
        
    }
    else {
        pvc.barButtonItem = sender;
    }
#else
    pvc.barButtonItem = sender;
#endif
    
    pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
    
    [self presentViewController:instance animated:YES completion:nil];
    
}

- (void)openArticleInNewWindow {
    
    NSUserActivity *openArticleActivity = [[NSUserActivity alloc] initWithActivityType:@"openArticle"];
    
    NSDictionary *dict = self.item.dictionaryRepresentation;
    
    [openArticleActivity addUserInfoEntriesFromDictionary:dict];
    
    UISceneActivationRequestOptions * options = [UISceneActivationRequestOptions new];
    options.requestingScene = self.view.window.windowScene;
#if TARGET_OS_MACCATALYST
    options.collectionJoinBehavior = UISceneCollectionJoinBehaviorDisallowed;
#endif
    
    [UIApplication.sharedApplication requestSceneSessionActivation:nil userActivity:openArticleActivity options:options errorHandler:^(NSError * _Nonnull error) {
        
        if (error != nil) {
            
            NSLog(@"Error occurred requesting new window session. %@", error.localizedDescription);
            
        }
        
    }];
    
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(nonnull UITraitCollection *)traitCollection
{
    return UIModalPresentationNone;
}

#pragma mark - Getters

- (void)removeSearchResultViewFromSuperview {
    if (_searchHighlightingRect) {
        [_searchHighlightingRect removeFromSuperview];
    }
    _searchHighlightingRect = nil;
}

#pragma mark - <UISearchBarDelegate>

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
//    _searchingRects = nil;
//    [self removeSearchResultViewFromSuperview];
    return YES;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self didTapSearchNext];
        return NO;
    }
    
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!searchText || [searchText isBlank]) {
        self.searchPrevButton.enabled = NO;
        self.searchNextButton.enabled = NO;
        [self removeSearchResultViewFromSuperview];
        return;
    }
    
    searchText = [searchText stringByStrippingWhitespace];
    
    NSLogDebug(@"Article search text: %@", searchText);
    
    NSArray <Paragraph *> *foundInViews = [[self.stackView arrangedSubviews] rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
       
        if ([obj isKindOfClass:Paragraph.class]) {
            
            Paragraph *para = (Paragraph *)obj;
            
            return [para.attributedText.string containsString:searchText];
            
        }
        
        return NO;
        
    }];
    
    if (![foundInViews count]) {
        self.searchPrevButton.enabled = NO;
        self.searchNextButton.enabled = NO;
        
        [self removeSearchResultViewFromSuperview];
        return;
    }
    
    if ([foundInViews count] == 1) {
        Paragraph *para = (Paragraph *)[foundInViews firstObject];
        NSString *text = para.attributedText.string;
        
        NSInteger occurrances = [self occurancesOfSubstring:searchText inString:text];
        
        if (occurrances <= 1)
            self.searchNextButton.enabled = NO;
        else
            self.searchNextButton.enabled = YES;
        
//        self.searchPrevButton.enabled = YES;
    }
    
    /* actual search ops */
    
    // first find all the ranges of the search text and their corresponding rects
    NSMutableArray <NSValue *> * rects = [NSMutableArray new];
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    
    [foundInViews enumerateObjectsUsingBlock:^(Paragraph * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *str = obj.attributedText.string;
        NSUInteger length = [str length];
        
        NSString *checkIn = str.lowercaseString;
        NSString *toCheck = searchText.lowercaseString;
        
        NSRange range = NSMakeRange(0, length);
        
        while(range.location != NSNotFound)
        {
            range = [checkIn rangeOfString:toCheck options:0 range:range];
            
            if(range.location != NSNotFound)
            {
                CGRect rect = [Paragraph boundingRectIn:obj forCharacterRange:range];
                rect = [obj convertRect:rect toView:obj.superview];
                
                NSValue *rectValue = [NSValue valueWithCGRect:rect];
                
                [rects addObject:rectValue];
                
                // advance the range for the next while loop
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            }
        }
        
    }];
    
    // now we can highlight across these rects
    _searchingRects = rects;
    
    asyncMain(^{
        scrollView.userInteractionEnabled = NO;
    });
    
    if (_searchingRects.count > 1) {
        self.searchNextButton.enabled = YES;
//        self.searchPrevButton.enabled = YES;
    }
    
    if (!_searchHighlightingRect) {
        
        // use the first rect's value
        _searchHighlightingRect = [[UIView alloc] initWithFrame:CGRectZero];
        _searchHighlightingRect.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
        _searchHighlightingRect.autoresizingMask = UIViewAutoresizingNone;
        _searchHighlightingRect.translatesAutoresizingMaskIntoConstraints = NO;
        _searchHighlightingRect.layer.cornerRadius = 4.f;
        _searchHighlightingRect.layer.masksToBounds = YES;
        
        // add it to the scrollview
        [scrollView addSubview:_searchHighlightingRect];
    }
    
//    _searchHighlightingRect.text = searchText;
    _searchCurrentIndex = 0;
    [self scrollToRangeRect:_searchingRects.firstObject];
    
    asyncMain(^{
        scrollView.userInteractionEnabled = YES;
    });
}

- (NSInteger)occurancesOfSubstring:(NSString *)substring inString:(NSString *)str {
    NSUInteger count = 0, length = [str length];
    NSRange range = NSMakeRange(0, length);
    
    NSString *checkIn = str.lowercaseString;
    NSString *toCheck = substring.lowercaseString;
    
    while(range.location != NSNotFound)
    {
        range = [checkIn rangeOfString:toCheck options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    
    return count;
}

@end
