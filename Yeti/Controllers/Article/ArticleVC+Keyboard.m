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
    
    UIKeyCommand *close = [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:UIKeyModifierCommand action:@selector(didTapClose) discoverabilityTitle:@"Close Article"];
    UIKeyCommand *bookmark = [UIKeyCommand keyCommandWithInput:@"b" modifierFlags:UIKeyModifierCommand action:@selector(didTapBookmark:) discoverabilityTitle:(self.item.isBookmarked ? @"Unbookmark Article" : @"Bookmark Article")];
    UIKeyCommand *read = [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(didTapRead:) discoverabilityTitle:(self.item.isRead ? @"Mark as Unread" : @"Mark as Read")];
    
    UIKeyCommand *search = [UIKeyCommand keyCommandWithInput:@"f" modifierFlags:UIKeyModifierCommand action:@selector(didTapSearch) discoverabilityTitle:@"Search article"];
    
    UIKeyCommand *scrollUp = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(scrollUp) discoverabilityTitle:@"Scroll Up"];
    UIKeyCommand *scrollDown = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(scrollDown) discoverabilityTitle:@"Scroll Down"];
    UIKeyCommand *previousArticle = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand action:@selector(didTapPreviousArticle:) discoverabilityTitle:@"Previous Article"];
    UIKeyCommand *nextArticle = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand action:@selector(didTapNextArticle:) discoverabilityTitle:@"Next article"];
    
    UIKeyCommand *galleryLeft = [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:@selector(navLeft) discoverabilityTitle:@"Previous Image"];
    UIKeyCommand *galleryRight = [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:@selector(navRight) discoverabilityTitle:@"Next Image"];
    
    UIKeyCommand *esc = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:@selector(didTapSearchDone)];
    
    NSArray <UIKeyCommand *> *commands = @[close, bookmark, read, search, scrollUp, scrollDown, galleryLeft, galleryRight, esc];
    
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
    
    // max height of ths scrollView
//    CGSize maxSize = scrollView.contentSize;
    
    CGPoint targetOffset = currentOffset;
    targetOffset.y = MAX(targetOffset.y - 150, -self.view.safeAreaInsets.top + 20.f);
    
    [scrollView setContentOffset:targetOffset animated:YES];
}

- (void)scrollDown {
    
    UIScrollView *scrollView = (UIScrollView *)[self.stackView superview];
    CGPoint currentOffset = scrollView.contentOffset;
    
    // max height of ths scrollView
    CGSize maxSize = scrollView.contentSize;
    
    CGPoint targetOffset = currentOffset;
    targetOffset.y = MIN(targetOffset.y + 150, maxSize.height - scrollView.bounds.size.height);
    
    [scrollView setContentOffset:targetOffset animated:YES];
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
    
    if (sender == nil || [sender respondsToSelector:@selector(setEnabled:)] == NO) {
        return;
    }
    
    if (self.providerDelegate == nil) {
        sender.enabled = NO;
        return;
    }
    
    FeedItem *article = [self.providerDelegate previousArticleFor:[self currentArticle]];
    
    if (article)
        [self setupArticle:article];
    else
        sender.enabled = NO;
    
    [self updateBarButtonItems];
}

- (void)didTapNextArticle:(UIButton *)sender {
    
    if (self.helperView) {
        [self.helperView didTapNextArticle:sender];
        return;
    }
    
    if (sender == nil || [sender respondsToSelector:@selector(setEnabled:)] == NO) {
        return;
    }
    
    if (self.providerDelegate == nil) {
        sender.enabled = NO;
        return;
    }
    
    FeedItem *article = [self.providerDelegate nextArticleFor:[self currentArticle]];
    
    if (article)
        [self setupArticle:article];
    else
        sender.enabled = NO;
    
    [self updateBarButtonItems];
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
