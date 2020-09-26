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

@implementation ArticleVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    UIKeyCommand *close = [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:UIKeyModifierCommand action:@selector(didTapClose)];
    close.title = @"Close";
    close.discoverabilityTitle = close.title;
    
    UIKeyCommand *bookmark = [UIKeyCommand keyCommandWithInput:@"b" modifierFlags:UIKeyModifierCommand action:@selector(didTapBookmark:)];
    bookmark.title = self.item.isBookmarked ? @"Unbookmark" : @"Bookmark";
    bookmark.discoverabilityTitle = bookmark.title;
    
    UIKeyCommand *read = [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(didTapRead:)];
    read.title = self.item.isRead ? @"Mark Unread" : @"Mark Read";
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
    
    UIKeyCommand *scrollUpAddtional = [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageUp" modifierFlags:0 action:@selector(scrollUp)];
    scrollUpAddtional.title = @"Scroll Up";
    
    UIKeyCommand *scrollDownAddtional = [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageDown" modifierFlags:0 action:@selector(scrollDown)];
    scrollDownAddtional.title = @"Scroll Up";
    
    UIKeyCommand *scrollToTop = [UIKeyCommand keyCommandWithInput:@"UIKeyInputHome" modifierFlags:0 action:@selector(scrollToTop)];
    scrollToTop.title = @"Scroll to Top";
    
    UIKeyCommand *scrollToEnd = [UIKeyCommand keyCommandWithInput:@"UIKeyInputEnd" modifierFlags:0 action:@selector(scrollToEnd)];
    scrollToTop.title = @"Scroll to End";
    
    UIKeyCommand *previousArticle = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand action:@selector(didTapPreviousArticle:)];
    previousArticle.title = @"Previous Article";
    previousArticle.discoverabilityTitle = previousArticle.title;
    
    UIKeyCommand *nextArticle = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand action:@selector(didTapNextArticle:)];
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
    
    NSArray <UIKeyCommand *> *commands = @[close, bookmark, read, search, scrollUp, scrollDown, galleryLeft, galleryRight, esc, scrollUpAddtional, scrollDownAddtional, scrollToTop, scrollToEnd];
    
    if ([self.providerDelegate hasNextArticleForArticle:self.item]) {
        commands = [commands arrayByAddingObject:nextArticle];
    }
    
    if ([self.providerDelegate hasPreviousArticleForArticle:self.item]) {
        commands = [commands arrayByAddingObject:previousArticle];
    }
    
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
    
    FeedItem *article = [self.providerDelegate previousArticleFor:[self currentArticle]];
    
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
    
    FeedItem *article = [self.providerDelegate nextArticleFor:[self currentArticle]];
    
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
    
    Gallery *gallery = (Gallery *)[visibleViews rz_reduce:^id(UIView *prev, UIView *current, NSUInteger idx, NSArray *array) {
        return prev || [current isKindOfClass:Gallery.class] ? current : nil;
    }];
    
    if (![gallery isKindOfClass:Gallery.class]) {
        return nil;
    }
    
    return gallery;
    
}

- (void)navLeft {
    
    Gallery *gallery = [self visibleGallery];
    
    if (!gallery) {
        return;
    }
    
    CGPoint contentOffset = gallery.collectionView.contentOffset;
    CGSize itemSize = [(UICollectionViewFlowLayout *)(gallery.collectionView.collectionViewLayout) itemSize];
    
    contentOffset.x = MAX(0, contentOffset.x - itemSize.width);
    
    [gallery.collectionView setContentOffset:contentOffset animated:YES];
    
}

- (void)navRight {
    
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
