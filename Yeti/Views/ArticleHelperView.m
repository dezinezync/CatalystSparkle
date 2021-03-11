//
//  ArticleHelperView.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleHelperView.h"
#import "YetiThemeKit.h"
#import "ArticleVC.h"
#import "PrefsManager.h"

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
        
        self.previousArticleButton.accessibilityLabel = @"Previous Article";
        self.nextArticleButton.accessibilityLabel = @"Next Article";
        self.startOfArticle.accessibilityLabel = @"Scroll to top";
        self.endOfArticle.accessibilityLabel = @"Scroll to end";
        
        self.layer.cornerRadius = 22.f;
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview != nil) {
        
        self.tintColor = SharedPrefs.tintColor;
        
        self.backgroundColor = UIColor.systemBackgroundColor;
        
        for (UIButton *button in @[self.previousArticleButton, self.nextArticleButton, self.startOfArticle, self.endOfArticle]) {
            
            button.tintColor = self.tintColor;
            
            button.imageView.image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            [button setNeedsDisplay];
            [button setNeedsLayout];
            
            if (@available(iOS 13.4, *)) {
                button.pointerInteractionEnabled = YES;
            }
        }
        
        [self configureForShadow];
        
        self.clipsToBounds = NO;
    }
}

- (void)updateShadowPath {
    
    [self tintColorDidChange];
    
    CGRect frame = self.bounds;
    frame.size.width = self.bounds.size.width;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.layer.cornerRadius];
    
//    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    
    self.layer.shadowPath = path.CGPath;
    self.layer.shadowColor = UIColor.separatorColor.CGColor; //dark ? [UIColor.blackColor colorWithAlphaComponent:0.35f].CGColor : [UIColor colorWithDisplayP3Red:138/255.f green:145/255.f blue:153/255.f alpha:0.5f].CGColor;
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
    ArticleVC *vc = (ArticleVC *)[scrollView valueForKey:@"delegate"];
    
    asyncMain(^{
        [scrollView setContentOffset:CGPointMake(0, -scrollView.adjustedContentInset.top) animated:YES];
        [[vc notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
        [[vc notificationGenerator] prepare];
    });
    
}

- (IBAction)didTapArticleEnd:(UIButton *)sender {
    
    if (![sender respondsToSelector:@selector(setEnabled:)]) {
        sender = [self.stackView.arrangedSubviews objectAtIndex:3];
    }
    
    UIScrollView *scrollView = (UIScrollView *)[[self.superview subviews] firstObject];
    CGSize contentSize = [scrollView contentSize];
    
    CGRect rect = CGRectMake(0, contentSize.height - scrollView.bounds.size.height, scrollView.bounds.size.width, scrollView.bounds.size.height);
    
    ArticleVC *vc = (ArticleVC *)[scrollView valueForKey:@"delegate"];
    
    asyncMain(^{
        [scrollView setContentOffset:CGPointMake(0, rect.origin.y + scrollView.adjustedContentInset.bottom) animated:YES];
        [[vc notificationGenerator] notificationOccurred:UINotificationFeedbackTypeSuccess];
        [[vc notificationGenerator] prepare];
    });
    
}

@end
