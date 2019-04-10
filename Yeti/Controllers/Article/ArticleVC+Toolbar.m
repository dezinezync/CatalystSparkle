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

#import "YetiThemeKit.h"

#import "Paragraph.h"
#import "FeedsManager.h"

#import "EmptyVC.h"
#import "SplitVC.h"
#import "FeedVC.h"
#import "YetiConstants.h"

#import <PopMenu/PopMenu.h>

@implementation ArticleVC (Toolbar)

- (void)setupToolbar:(UITraitCollection *)newCollection
{
    
    UIBarButtonItem *read = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"read"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapRead:)];
    read.accessibilityValue = @"Mark article unread";
    read.accessibilityLabel = @"Read state";
    
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed: self.item.isBookmarked ? @"bookmark" : @"unbookmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapBookmark:)];
    
    bookmark.accessibilityValue = self.item.isBookmarked ? @"Remove from bookmarks" : @"Bookmark article";
    bookmark.accessibilityLabel = @"Bookmarked";
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapShare:)];
    
    share.accessibilityValue = @"Share article";
    share.accessibilityLabel = @"Share";
    
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSearch)];
    
    search.accessibilityValue = @"Search in article";
    search.accessibilityLabel = @"Search";
    
    UIBarButtonItem *browser = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"open_in_browser"] style:UIBarButtonItemStylePlain target:self action:@selector(openInBrowser)];
    browser.accessibilityValue = @"Open the article in the browser";
    browser.accessibilityLabel = @"Browser";
    
    self.toolbarItems = nil;
    self.navigationController.toolbarHidden = YES;
    // these are assigned in reverse order
    NSMutableArray *rightItems = @[share, search].mutableCopy;
    
    if (PrefsManager.sharedInstance.hideBookmarks == NO) {
        [rightItems addObject:bookmark];
    }
    
    [rightItems addObjectsFromArray:@[read, browser]];
    
    self.navigationItem.rightBarButtonItems = rightItems;
    
    if (newCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
//        UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(didTapClose)];
        
        UIBarButtonItem *displayButton = [(UISplitViewController *)[UIApplication.sharedApplication.keyWindow rootViewController] displayModeButtonItem];
        self.navigationItem.leftBarButtonItem = displayButton;
//        if (self.navigationItem.leftBarButtonItem) {
//            if (self.navigationItem.leftBarButtonItem == displayButton) {
//                self.navigationItem.leftBarButtonItems = @[self.navigationItem.leftBarButtonItem, close];
//            }
//            else {
//                self.navigationItem.leftBarButtonItems = @[self.navigationItem.leftBarButtonItem, displayButton, close];
//            }
//        }
//        else {
//            self.navigationItem.leftBarButtonItems = @[displayButton, close];
//        }
    }
    else {
        self.navigationItem.leftBarButtonItems = nil;
    }
}

#pragma mark - Actions

- (void)didTapClose {
    
    SplitVC *vc = (SplitVC *)[self splitViewController];
    
    UINavigationController *emptyVC = [vc emptyVC];
    [vc showDetailViewController:emptyVC sender:self];
    
    UINavigationController *nav = vc.viewControllers.firstObject;
    FeedVC *top = (FeedVC *)[nav topViewController];
    
    if (top != nil && ([top isKindOfClass:FeedVC.class] || [top.class isSubclassOfClass:FeedVC.class])) {
        NSIndexPath *selected = [top.tableView indexPathForSelectedRow];
        
        if (selected != nil) {
            [top.tableView deselectRowAtIndexPath:selected animated:YES];
        }
    }
}

- (void)didTapShare:(UIBarButtonItem *)sender {
    
    if (!self.item)
        return;
    
    NSString *title = self.item.articleTitle;
    NSURL *URL = formattedURL(@"%@", self.item.articleURL);
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, @" ", URL] applicationActivities:nil];
    
//    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.barButtonItem = sender;
        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        
//    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

- (void)didTapBookmark:(UIBarButtonItem *)button {
    
    if (![button respondsToSelector:@selector(setEnabled:)]) {
        button = [self.navigationItem.rightBarButtonItems objectAtIndex:2];
    }
    
    button.enabled = NO;
    
    weakify(self);
    
    [MyFeedsManager article:self.item markAsBookmarked:(!self.item.isBookmarked) success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        BOOL errored = self.item.isBookmarked ? [MyFeedsManager addLocalBookmark:self.item] : [MyFeedsManager removeLocalBookmark:self.item];
        
        if (!errored) {
            button.image = self.item.isBookmarked ? [UIImage imageNamed:@"bookmark"] : [UIImage imageNamed:@"unbookmark"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksDidUpdate object:self.item userInfo:@{@"bookmarked": @(self.item.isBookmarked)}];
        }
        else {
            self.item.bookmarked = !self.item.bookmarked;
        }
        
        if (self.providerDelegate && [self.providerDelegate respondsToSelector:@selector(userMarkedArticle:bookmarked:)]) {
            [self.providerDelegate userMarkedArticle:self.item bookmarked:self.item.bookmarked];
        }
     
        button.enabled = YES;
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            strongify(self);
            
            [[self notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
            [[self notificationGenerator] prepare];
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Service Error" message:error.localizedDescription];
        
        button.enabled = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            [[self notificationGenerator] notificationOccurred:UINotificationFeedbackTypeError];
            [[self notificationGenerator] prepare];
            
        });
        
    }];
}

- (void)didTapRead:(UIBarButtonItem *)button {
    
    if (![button respondsToSelector:@selector(setEnabled:)]) {
        button = [self.navigationItem.rightBarButtonItems objectAtIndex:3];
    }
    
    button.enabled = NO;
    
    [MyFeedsManager article:self.item markAsRead:!self.item.isRead];
    self.item.read = !self.item.isRead;
    button.image = self.item.isRead ? [UIImage imageNamed:@"read"] : [UIImage imageNamed:@"unread"];
    
    if (self.providerDelegate && [self.providerDelegate respondsToSelector:@selector(userMarkedArticle:read:)]) {
        
        [self.providerDelegate userMarkedArticle:self.item read:self.item.read];
        
    }
    
    button.enabled = YES;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [[self notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
        [[self notificationGenerator] prepare];
        
    });
    
}

- (void)openInBrowser {
    NSURL *URL = formattedURL(@"yeti://external?link=%@", self.item.articleURL);
    
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

- (void)didTapSearch
{
    
    if (_showSearchBar == YES) {
        [self didTapSearchDone];
        return;
    }
    
    _showSearchBar = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadInputViews];
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
    
    [self.searchView removeFromSuperview];
    
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
            self->_searchHighlightingRect.frame = prevValue.CGRectValue;
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
        _searchHighlightingRect.frame = nextValue.CGRectValue;
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
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self scrollToRangeRect:value];
        });
        
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
        self->_searchHighlightingRect.frame = frame;
    });
}

#pragma mark - <UIAdaptivePresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        return UIModalPresentationPopover;
    }
    
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

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    _searchingRects = nil;
    [self removeSearchResultViewFromSuperview];
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
    
    DDLogDebug(@"Article search text: %@", searchText);
    
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
        
        self.searchPrevButton.enabled = YES;
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
        self.searchPrevButton.enabled = YES;
    }
    
    if (!_searchHighlightingRect) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        // use the first rect's value
        _searchHighlightingRect = [[UIView alloc] initWithFrame:CGRectZero];
        _searchHighlightingRect.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
        _searchHighlightingRect.autoresizingMask = UIViewAutoresizingNone;
        _searchHighlightingRect.translatesAutoresizingMaskIntoConstraints = NO;
        _searchHighlightingRect.layer.cornerRadius = 2.f;
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
