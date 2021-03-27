//
//  ArticleVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"
#import <DZKit/NSArray+RZArrayCandy.h>
#import "Gallery.h"
#import "UITextField+CursorPosition.h"
#import "Elytra-Swift.h"

@implementation ArticleVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    UIKeyCommand *close = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:UIKeyModifierCommand action:@selector(didTapClose)];
    close.title = @"Close";
    close.discoverabilityTitle = close.title;
    
    UIKeyCommand *openInBrowser = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:UIKeyModifierCommand action:@selector(openInBrowser)];
    openInBrowser.title = @"Open in Browser";
    openInBrowser.discoverabilityTitle = openInBrowser.title;
    
    UIKeyCommand *bookmark = [UIKeyCommand keyCommandWithInput:@"b" modifierFlags:UIKeyModifierCommand action:@selector(didTapBookmark:)];
    bookmark.title = self.item.bookmarked ? @"Unbookmark" : @"Bookmark";
    bookmark.discoverabilityTitle = bookmark.title;
    
    UIKeyCommand *read = [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(didTapRead:)];
    read.title = self.item.read ? @"Mark Unread" : @"Mark Read";
    read.discoverabilityTitle = read.title;
    
    UIKeyCommand *search = [UIKeyCommand keyCommandWithInput:@"f" modifierFlags:UIKeyModifierCommand action:@selector(didTapSearch)];
    search.title = @"Search";
    search.discoverabilityTitle = search.title;
    
    UIKeyCommand *scrollUp = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:UIKeyModifierShift action:@selector(scrollUp)];
    scrollUp.title = @"Scroll Up";
    scrollUp.discoverabilityTitle = scrollUp.title;
    
    UIKeyCommand *scrollDown = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(scrollDown)];
    scrollDown.title = @"Scroll Down";
    scrollDown.discoverabilityTitle = scrollDown.title;
    
#if TARGET_OS_MACCATALYST
    UIKeyCommand *scrollUpAddtional = [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageUp" modifierFlags:0 action:@selector(scrollUp)];
    scrollUpAddtional.title = @"Scroll Up";
    
    UIKeyCommand *scrollDownAddtional = [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageDown" modifierFlags:0 action:@selector(scrollDown)];
    scrollDownAddtional.title = @"Scroll Down";
    
    UIKeyCommand *scrollToTop = [UIKeyCommand keyCommandWithInput:@"UIKeyInputHome" modifierFlags:0 action:@selector(scrollToTop)];
    scrollToTop.title = @"Scroll to Top";
    
    UIKeyCommand *scrollToEnd = [UIKeyCommand keyCommandWithInput:@"UIKeyInputEnd" modifierFlags:0 action:@selector(scrollToEnd)];
    scrollToTop.title = @"Scroll to End";
#endif
    
    UIKeyCommand *previousArticle = [UIKeyCommand keyCommandWithInput:@"j" modifierFlags:0 action:@selector(didTapPreviousArticle:)];
    previousArticle.title = @"Previous Article";
    previousArticle.discoverabilityTitle = previousArticle.title;
    
    UIKeyCommand *nextArticle = [UIKeyCommand keyCommandWithInput:@"k" modifierFlags:0 action:@selector(didTapNextArticle:)];
    nextArticle.title = @"Next Article";
    nextArticle.discoverabilityTitle = nextArticle.title;
    
    UIKeyCommand *galleryLeft = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(navLeft)];
    galleryLeft.title = @"Previous Image";
    galleryLeft.discoverabilityTitle = galleryLeft.title;
    
    UIKeyCommand *galleryRight = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(navRight)];
    galleryRight.title = @"Next Image";
    galleryRight.discoverabilityTitle = galleryRight.title;
    
    UIKeyCommand *esc = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(didTapSearchDone)];
    esc.title = @"Dismiss Search";
    esc.discoverabilityTitle = esc.title;
    
    UIKeyCommand *searchPrevious = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierShift action:@selector(didTapSearchPrevious)];
    searchPrevious.title = @"Previous Search Result";
    
    NSArray <UIKeyCommand *> *commands = @[close, bookmark, read, search, scrollUp, scrollDown, galleryLeft, galleryRight, esc, previousArticle, nextArticle, openInBrowser, searchPrevious];
    
#if TARGET_OS_MACCATALYST
    commands = [commands arrayByAddingObjectsFromArray:@[scrollUpAddtional, scrollDownAddtional, scrollToTop, scrollToEnd]];
#endif
    
    return commands;
    
}

- (void)scrollUp {
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    CGPoint currentOffset = scrollView.contentOffset;
    
    CGPoint targetOffset = currentOffset;
    
    CGFloat addOffset = 150.f;
    
#if TARGET_OS_MACCATALYST
    // offset by 3/4th of the page. This assumes
    // the reader is reading the last few lines
    // and wants to bring the lines "above the fold"
    addOffset = floor(scrollView.bounds.size.height * 0.75f);
#endif
    
    targetOffset.y -= addOffset;
    
    targetOffset.y = MAX(targetOffset.y, -self.view.safeAreaInsets.top);
    
    [scrollView setContentOffset:targetOffset animated:YES];
}

- (void)scrollDown {
    
    if (self.searchBar.isFirstResponder) {
        
        self.searchBar.text = [self.searchBar.text stringByAppendingString:@" "];
        
        return;
    }
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    CGPoint currentOffset = scrollView.contentOffset;
    
    // max height of ths scrollView
    CGSize maxSize = scrollView.contentSize;
    
    CGPoint targetOffset = currentOffset;
    
    CGFloat addOffset = 150.f;
    
#if TARGET_OS_MACCATALYST
    // offset by 3/4th of the page. This assumes
    // the reader is reading the last few lines
    // and wants to bring the lines "above the fold"
    addOffset = floor(scrollView.bounds.size.height * 0.75f);
#endif
    
    targetOffset.y += addOffset;
    
    targetOffset.y = MIN(targetOffset.y, maxSize.height - scrollView.bounds.size.height);
    
    [scrollView setContentOffset:targetOffset animated:YES];
}

- (void)scrollToTop {
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    
    [scrollView setContentOffset:CGPointMake(0, -scrollView.adjustedContentInset.top) animated:YES];
    
}


- (void)scrollToEnd {
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    
    CGSize contentSize = scrollView.contentSize;
    
    CGRect rect = CGRectMake(0, contentSize.height - scrollView.bounds.size.height, scrollView.bounds.size.width, scrollView.bounds.size.height);
    
    [scrollView setContentOffset:CGPointMake(0, rect.origin.y + scrollView.adjustedContentInset.bottom) animated:YES];
    
}

- (void)updateBarButtonItems {

    if (self.providerDelegate == nil
        || _prevButtonItem == nil
        || _nextButtonItem == nil) {
        return;
    }
    
    BOOL next = [self.providerDelegate hasPreviousArticleForArticle:self.item];
    BOOL previous = [self.providerDelegate hasNextArticleForArticle:self.item];
    
    _prevButtonItem.enabled = previous;
    _nextButtonItem.enabled = next;
    
}

- (void)didTapPreviousArticle:(UIButton *)sender {
    
    if (self.helperView) {
        [self.helperView didTapPreviousArticle:sender];
        return;
    }
    
    if (self.providerDelegate == nil) {
        
        if (sender != nil && [sender respondsToSelector:@selector(setEnabled:)] == YES) {
            
            sender.enabled = NO;
            
        }
        
        return;
    }
    
    Article *article = [self.providerDelegate previousArticleFor:[self currentArticle]];
    
    if (article) {
        [self setupArticle:article];
    }
    else {
        
        if (sender != nil && [sender respondsToSelector:@selector(setEnabled:)] == YES) {
            
            sender.enabled = NO;
            
        }
        
    }
    
#if !TARGET_OS_MACCATALYST
    [self updateBarButtonItems];
#endif
}

- (void)didTapNextArticle:(UIButton *)sender {
    
    if (self.helperView) {
        [self.helperView didTapNextArticle:sender];
        return;
    }
    
    if (self.providerDelegate == nil) {
        
        if (sender != nil && [sender respondsToSelector:@selector(setEnabled:)] == YES) {
            
            sender.enabled = NO;
            
        }
        
        return;
    }
    
    Article *article = [self.providerDelegate nextArticleFor:[self currentArticle]];
    
    if (article) {
        [self setupArticle:article];
    }
    else {
        
        if (sender != nil && [sender respondsToSelector:@selector(setEnabled:)] == YES) {
            
            sender.enabled = NO;
            
        }
        
    }
    
#if !TARGET_OS_MACCATALYST
    [self updateBarButtonItems];
#endif
    
}

#pragma mark - Gallery Nav

- (Gallery * _Nullable)visibleGallery {
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.bounds.size;
    
    NSArray <UIView *> *visibleViews = [[self.stackView arrangedSubviews] rz_filter:^BOOL(__kindof UIView *obj, NSUInteger idx, NSArray *array) {
        
        return CGRectIntersectsRect(visibleRect, CGRectOffset(obj.frame, 0, 48.f));
        
    }];
    
    Gallery *gallery = (Gallery *)[visibleViews rz_find:^BOOL(UIView *obj, NSUInteger idx, NSArray *array) {
        return [obj isKindOfClass:Gallery.class];
    }];
    
    if (![gallery isKindOfClass:Gallery.class]) {
        return nil;
    }
    
    return gallery;
    
}

- (void)navLeft {
    
    if (self.searchBar.isFirstResponder) {
        
        NSInteger cursorPos = self.searchBar.searchTextField.cursorPosition;
        cursorPos = MAX(0, cursorPos - 1);
        
        self.searchBar.searchTextField.cursorPosition = cursorPos;
        
        return;
    }
    
    Gallery *gallery = [self visibleGallery];
    
    if (!gallery) {
        return;
    }
    
    CGPoint contentOffset = gallery.collectionView.contentOffset;
    CGSize itemSize = [(UICollectionViewFlowLayout *)(gallery.collectionView.collectionViewLayout) itemSize];
    
    contentOffset.x = MIN(0, contentOffset.x - itemSize.width);
    
    [gallery.collectionView setContentOffset:contentOffset animated:YES];
    
}

- (void)navRight {
    
    if (self.searchBar.isFirstResponder) {
        
        NSInteger cursorPos = self.searchBar.searchTextField.cursorPosition;
        
        if (self.searchBar.text != nil) {
            cursorPos = MIN(self.searchBar.text.length, cursorPos + 1);
        }
        
        self.searchBar.searchTextField.cursorPosition = cursorPos;
        
        return;
    }
    
    Gallery *gallery = [self visibleGallery];
    
    if (!gallery) {
        return;
    }
    
    CGPoint contentOffset = gallery.collectionView.contentOffset;
    CGSize itemSize = [(UICollectionViewFlowLayout *)(gallery.collectionView.collectionViewLayout) itemSize];
    
    contentOffset.x = MIN(gallery.collectionView.contentSize.width - itemSize.width, contentOffset.x + itemSize.width);
    
    [gallery.collectionView setContentOffset:contentOffset animated:YES];
}

@end
