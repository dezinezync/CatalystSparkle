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

@implementation ArticleVC (Toolbar)

- (void)setupToolbar:(UITraitCollection *)newCollection
{
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didTapShare:)];
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(didTapSearch)];
    
    self.toolbarItems = nil;
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.rightBarButtonItems = @[search, share];
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
    
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[title, URL] applicationActivities:nil];
    
//    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.barButtonItem = sender;
        pvc.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        
//    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
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
    
}

- (void)didTapSearchNext
{
    
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
        
        _searchView = [[UIInputView alloc] initWithFrame:frame];
        [_searchView setValue:@(UIInputViewStyleKeyboard) forKeyPath:@"inputViewStyle"];
        
        [_searchView addSubview:_searchBar];
        
        [_searchBar.heightAnchor constraintEqualToConstant:36.f].active = YES;
        
        UIButton *prev = [UIButton buttonWithType:UIButtonTypeSystem];
        [prev setImage:[UIImage imageNamed:@"arrow_up"] forState:UIControlStateNormal];
        prev.bounds = CGRectMake(0, 0, 24.f, 24.f);
        prev.translatesAutoresizingMaskIntoConstraints = NO;
        [prev addTarget:self action:@selector(didTapSearchPrevious) forControlEvents:UIControlEventTouchUpInside];
        
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

#pragma mark - <UISearchBarDelegate>

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!searchText || [searchText isBlank]) {
        _searchPrevButton.enabled = NO;
        _searchNextButton.enabled = NO;
        return;
    }
    
    DDLogDebug(@"Article search text: %@", searchText);
    
    NSArray <UIView *> *foundInViews = [[self.stackView arrangedSubviews] rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
       
        if ([obj isKindOfClass:Paragraph.class]) {
            
            Paragraph *para = (Paragraph *)obj;
            
            return [para.attributedText.string containsString:searchText];
            
        }
        
        return NO;
        
    }];
    
    if (![foundInViews count]) {
        _searchPrevButton.enabled = NO;
        _searchNextButton.enabled = NO;
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
}

- (NSInteger)occurancesOfSubstring:(NSString *)substring inString:(NSString *)str {
    NSUInteger count = 0, length = [str length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound)
    {
        range = [str rangeOfString:substring options:0 range:range];
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    
    return count;
}

@end
