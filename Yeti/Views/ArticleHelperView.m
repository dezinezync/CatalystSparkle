//
//  ArticleHelperView.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleHelperView.h"
#import "YetiThemeKit.h"

@implementation ArticleHelperView


- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.accessibilityTraits = UIAccessibilityTraitTabBar;
        self.isAccessibilityElement = NO;
        
        self.previousArticleButton.accessibilityValue = @"Previous article";
        self.nextArticleButton.accessibilityValue = @"Next article";
        self.startOfArticle.accessibilityValue = @"Scroll to beginning of the article";
        self.endOfArticle.accessibilityValue = @"Scroll to end of the article";
        
        self.layer.cornerRadius = 22.f;
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview != nil) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.tintColor = theme.tintColor;
        
        self.backgroundColor = theme.cellColor;
        for (UIButton *button in @[self.previousArticleButton, self.nextArticleButton, self.startOfArticle, self.endOfArticle]) {
            button.tintColor = theme.tintColor;
            
            button.imageView.image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            button.translatesAutoresizingMaskIntoConstraints = NO;
            [button setNeedsDisplay];
            [button setNeedsLayout];
        }
        
        [self configureForShadow];
        self.clipsToBounds = NO;
    }
}

- (void)updateShadowPath
{
    
    CGRect frame = self.bounds;
    frame.size.width = self.bounds.size.width;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.layer.cornerRadius];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.layer.shadowPath = path.CGPath;
    self.layer.shadowColor = theme.isDark ? [UIColor.blackColor colorWithAlphaComponent:0.35f].CGColor : [UIColor colorWithDisplayP3Red:138/255.f green:145/255.f blue:153/255.f alpha:0.5f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = 8.f;
    self.layer.shadowOffset = CGSizeMake(0, 4.f);
    
    [self setNeedsDisplay];
}

#pragma mark - Actions

- (IBAction)didTapPreviousArticle:(UIButton *)sender {
    
    if (![sender respondsToSelector:@selector(setEnabled:)]) {
        sender = [self.stackView.arrangedSubviews objectAtIndex:1];
    }
    
    if (!self.providerDelegate) {
        sender.enabled = NO;
        return;
    }
    
    FeedItem *article = [self.providerDelegate previousArticleFor:[self.handlerDelegate currentArticle]];
    
    if (article)
        [self.handlerDelegate setupArticle:article];
    else
        sender.enabled = NO;
    
}

- (IBAction)didTapNextArticle:(UIButton *)sender {
    
    if (![sender respondsToSelector:@selector(setEnabled:)]) {
        sender = [self.stackView.arrangedSubviews objectAtIndex:0];
    }
    
    if (!self.providerDelegate) {
        sender.enabled = NO;
        return;
    }
    
    FeedItem *article = [self.providerDelegate nextArticleFor:[self.handlerDelegate currentArticle]];
    
    if (article)
        [self.handlerDelegate setupArticle:article];
    else
        sender.enabled = NO;
    
}

- (IBAction)didTapArticleTop:(UIButton *)sender {
    
    if (![sender respondsToSelector:@selector(setEnabled:)]) {
        sender = [self.stackView.arrangedSubviews objectAtIndex:2];
    }
    
    UIScrollView *scrollView = (UIScrollView *)[[self.superview subviews] firstObject];
//    CGSize contentSize = [scrollView contentSize];
    
//    sender.enabled = NO;
//    self.endOfArticle.enabled = YES;
    
    asyncMain(^{
        [scrollView setContentOffset:CGPointMake(0, -scrollView.adjustedContentInset.top) animated:YES];
    });
    
}

- (IBAction)didTapArticleEnd:(UIButton *)sender {
    
    if (![sender respondsToSelector:@selector(setEnabled:)]) {
        sender = [self.stackView.arrangedSubviews objectAtIndex:3];
    }
    
    UIScrollView *scrollView = (UIScrollView *)[[self.superview subviews] firstObject];
    CGSize contentSize = [scrollView contentSize];
    
//    sender.enabled = NO;
//    self.startOfArticle.enabled = YES;
    
    CGRect rect = CGRectMake(0, contentSize.height - scrollView.bounds.size.height, scrollView.bounds.size.width, scrollView.bounds.size.height);
    
    asyncMain(^{
        [scrollView setContentOffset:CGPointMake(0, rect.origin.y + scrollView.adjustedContentInset.bottom) animated:YES];
    });
    
}

@end
