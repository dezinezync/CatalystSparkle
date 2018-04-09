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

#import "Paragraph.h"
#import "FeedsManager.h"

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
    
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(didTapSearch)];
    
    search.accessibilityValue = @"Search in article";
    search.accessibilityLabel = @"Search";
    
    self.toolbarItems = nil;
    self.navigationController.toolbarHidden = YES;
    // these are assigned in reverse order
    self.navigationItem.rightBarButtonItems = @[share, search, bookmark, read];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputAccessoryView
{
    if (_showSearchBar)
        return self.searchView;
    return nil;
}

#pragma mark - Actions

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
    button.enabled = NO;
    
    self.item.bookmarked = !self.item.isBookmarked;
    button.image = self.item.isBookmarked ? [UIImage imageNamed:@"bookmark"] : [UIImage imageNamed:@"unbookmark"];
    
    button.enabled = YES;
}

- (void)didTapRead:(UIBarButtonItem *)button {
    
    button.enabled = NO;
    
    [MyFeedsManager article:self.item markAsRead:!self.item.isRead];
    self.item.read = !self.item.isRead;
    button.image = self.item.isRead ? [UIImage imageNamed:@"read"] : [UIImage imageNamed:@"unread"];
    
    if (self.providerDelegate && [self.providerDelegate respondsToSelector:@selector(userMarkedArticle:read:)]) {
        
        [self.providerDelegate userMarkedArticle:self.item read:self.item.read];
        
    }
    
    button.enabled = YES;
    
}

- (void)didTapSearch
{
    _showSearchBar = YES;
    [self reloadInputViews];
    [_searchBar becomeFirstResponder];
}

- (void)didTapSearchDone
{
    _showSearchBar = NO;
    [_searchBar resignFirstResponder];
    [self reloadInputViews];
}

- (void)didTapSearchPrevious
{
    if (_searchCurrentIndex == 0) {
        // we are on the first possible result. This shouldn't be possible.
        _searchPrevButton.enabled = NO;
        return;
    }
    
    NSValue *prevValue = _searchingRects[_searchCurrentIndex-1];
    
    if (prevValue) {
        _searchCurrentIndex--;
        _searchHighlightingRect.frame = prevValue.CGRectValue;
        [self scrollToRangeRect:prevValue];
    }
    
    if (_searchCurrentIndex == 0)
        _searchPrevButton.enabled = NO;
    
    // if previous was tappable, next should be tappable now
    if (!_searchNextButton.isEnabled)
        _searchNextButton.enabled = YES;
}

- (void)didTapSearchNext
{
    if (_searchCurrentIndex == (_searchingRects.count-1)) {
        // we are on the last result. This shouldn't be possible.
        _searchNextButton.enabled = NO;
        return;
    }
    
    NSValue *nextValue = _searchingRects[_searchCurrentIndex+1];
    if (nextValue) {
        _searchCurrentIndex++;
        _searchHighlightingRect.frame = nextValue.CGRectValue;
        [self scrollToRangeRect:nextValue];
    }
    
    if (_searchCurrentIndex == (_searchingRects.count - 1))
        _searchNextButton.enabled = NO;
    
    // if next was tappable, previous should be tappable now
    if (!_searchPrevButton.isEnabled)
        _searchPrevButton.enabled = YES;
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
    
    CGRect rect = value.CGRectValue;
    UIScrollView *scrollView = (UIScrollView *)(self.stackView.superview);
    // since we reference the scrollRect from 0,0 (top, left) in iOS.
    rect.origin.y += scrollView.adjustedContentInset.top;
    
    [scrollView scrollRectToVisible:rect animated:YES];
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

- (UIInputView *)searchView
{
    if (!_searchView) {
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, 52.f);
        
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(64.f, 8.f, frame.size.width - 64.f - 56.f , frame.size.height - 16.f)];
        _searchBar.placeholder = @"Search article";
        _searchBar.keyboardType = UIKeyboardTypeDefault;
        _searchBar.returnKeyType = UIReturnKeySearch;
        _searchBar.delegate = self;
//        _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
//        [_searchBar setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        
        _searchBar.backgroundColor = UIColor.clearColor;
        _searchBar.backgroundImage = nil;
        _searchBar.scopeBarBackgroundImage = nil;
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        _searchBar.translucent = NO;
        _searchBar.accessibilityHint = @"Search keywords in article";
        
        _searchView = [[UIInputView alloc] initWithFrame:frame];
        [_searchView setValue:@(UIInputViewStyleKeyboard) forKeyPath:@"inputViewStyle"];
        
        [_searchView addSubview:_searchBar];
        
        [_searchBar.heightAnchor constraintEqualToConstant:36.f].active = YES;
        
        UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
        [prev setImage:[UIImage imageNamed:@"arrow_up"] forState:UIControlStateNormal];
        prev.bounds = CGRectMake(0, 0, 24.f, 24.f);
        prev.translatesAutoresizingMaskIntoConstraints = NO;
        [prev addTarget:self action:@selector(didTapSearchPrevious) forControlEvents:UIControlEventTouchUpInside];
        prev.accessibilityHint = @"Previous search result";
        
        frame = prev.bounds;
        
        [_searchView addSubview:prev];
        
        [prev.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [prev.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [prev.leadingAnchor constraintEqualToAnchor:_searchView.leadingAnchor constant:8.f].active = YES;
        [prev.centerYAnchor constraintEqualToAnchor:_searchView.centerYAnchor].active = YES;
        
        UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
        [next setImage:[UIImage imageNamed:@"arrow_down"] forState:UIControlStateNormal];
        next.bounds = CGRectMake(0, 0, 24.f, 24.f);
        next.translatesAutoresizingMaskIntoConstraints = NO;
        [next addTarget:self action:@selector(didTapSearchNext) forControlEvents:UIControlEventTouchUpInside];
        next.accessibilityHint = @"Next search result";
        
        frame = next.bounds;
        
        [_searchView addSubview:next];
        
        [next.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [next.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [next.leadingAnchor constraintEqualToAnchor:prev.trailingAnchor constant:8.f].active = YES;
        [next.centerYAnchor constraintEqualToAnchor:_searchView.centerYAnchor].active = YES;
        
        prev.tintColor = UIColor.blackColor;
        next.tintColor = UIColor.blackColor;
        
        UIButton *done = [UIButton buttonWithType:UIButtonTypeSystem];
        done.translatesAutoresizingMaskIntoConstraints = NO;
        done.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        [done setTitle:@"Done" forState:UIControlStateNormal];
        [done setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        [done sizeToFit];
        
        done.accessibilityHint = @"Dismiss search";
        
        [done addTarget:self action:@selector(didTapSearchDone) forControlEvents:UIControlEventTouchUpInside];
        
        frame = done.bounds;
        
        [_searchView addSubview:done];
//        [done.widthAnchor constraintEqualToConstant:frame.size.width].active = YES;
        [done.heightAnchor constraintEqualToConstant:frame.size.height].active = YES;
        [done.trailingAnchor constraintEqualToAnchor:_searchView.trailingAnchor constant:-8.f].active = YES;
        [done.centerYAnchor constraintEqualToAnchor:_searchView.centerYAnchor].active = YES;
        
        _searchPrevButton = prev;
        _searchNextButton = next;
        
        _searchPrevButton.enabled = NO;
        _searchNextButton.enabled = NO;
    }
    
    return _searchView;
}

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

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!searchText || [searchText isBlank]) {
        _searchPrevButton.enabled = NO;
        _searchNextButton.enabled = NO;
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
        _searchPrevButton.enabled = NO;
        _searchNextButton.enabled = NO;
        
        [self removeSearchResultViewFromSuperview];
        return;
    }
    
    if ([foundInViews count] == 1) {
        Paragraph *para = (Paragraph *)[foundInViews firstObject];
        NSString *text = para.attributedText.string;
        
        NSInteger occurrances = [self occurancesOfSubstring:searchText inString:text];
        
        if (occurrances <= 1)
            _searchNextButton.enabled = NO;
        else
            _searchNextButton.enabled = YES;
        
        _searchPrevButton.enabled = YES;
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
//        NSMutableArray <NSValue *> *subranges = @[].mutableCopy;
        
        NSTextStorage *textStorage = obj.textStorage;
        NSLayoutManager *layoutManager = [[textStorage layoutManagers] firstObject];
        NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];
        
        while(range.location != NSNotFound)
        {
            range = [checkIn rangeOfString:toCheck options:0 range:range];
            if(range.location != NSNotFound)
            {
                CGRect rect = [layoutManager boundingRectForGlyphRange:range inTextContainer:textContainer];
                rect = [obj convertRect:rect toView:obj.superview];
                
//                UIEdgeInsets adjustedInsets = scrollView.adjustedContentInset;
//                UIEdgeInsets contentInsets = scrollView.contentInset;
                
                rect.origin.y += 16.f;//(((adjustedInsets.bottom - contentInsets.bottom) + (adjustedInsets.top - contentInsets.top))/2.f) - 2.5f;
                rect.origin.x += 16.f;
                
                NSValue *rectValue = [NSValue valueWithCGRect:rect];
                
                [rects addObject:rectValue];
                
                // advance the range for the next while loop
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            }
        }
        
    }];
    
    // now we can highlight across these rects
    _searchingRects = rects;
    
    if (!_searchHighlightingRect) {
        // use the first rect's value
        _searchHighlightingRect = [[UILabel alloc] initWithFrame:CGRectIntegral(_searchingRects.firstObject.CGRectValue)];
        _searchHighlightingRect.backgroundColor = [UIColor.yellowColor colorWithAlphaComponent:0.5f];
        _searchHighlightingRect.autoresizingMask = UIViewAutoresizingNone;
        _searchHighlightingRect.numberOfLines = 0;
        _searchHighlightingRect.font = [[[Paragraph alloc] init] bodyFont];
        _searchHighlightingRect.layer.cornerRadius = 2.f;
        _searchHighlightingRect.layer.masksToBounds = YES;
        
        // add it to the scrollview
        [scrollView addSubview:_searchHighlightingRect];
//        [scrollView sendSubviewToBack:_searchHighlightingRect];
    }
    else {
        // it's already there. update it's frame
        _searchHighlightingRect.frame = CGRectIntegral(_searchingRects.firstObject.CGRectValue);
    }
    
//    _searchHighlightingRect.text = searchText;
    _searchCurrentIndex = 0;
    [self scrollToRangeRect:_searchingRects.firstObject];
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
