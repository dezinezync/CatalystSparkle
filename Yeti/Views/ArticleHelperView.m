//
//  ArticleHelperView.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleHelperView.h"

@implementation ArticleHelperView


- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.accessibilityTraits = UIAccessibilityTraitTabBar;
        self.isAccessibilityElement = NO;
        
        for (UIButton *button in @[self.previousArticleButton, self.nextArticleButton, self.startOfArticle, self.endOfArticle]) {
            button.imageView.image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            button.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
        self.previousArticleButton.accessibilityLabel = @"Previous article";
        self.nextArticleButton.accessibilityLabel = @"Next article";
        self.startOfArticle.accessibilityLabel = @"Start of article";
        self.endOfArticle.accessibilityLabel = @"End of article";
        
        self.layer.cornerRadius = 22.f;
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview != nil) {
        [self configureForShadow];
        self.clipsToBounds = NO;
    }
}

- (void)updateShadowPath
{
    
    CGRect frame = self.bounds;
    frame.size.width = self.bounds.size.width;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.layer.cornerRadius];
    
    self.layer.shadowPath = path.CGPath;
    self.layer.shadowColor = [UIColor colorWithDisplayP3Red:138/255.f green:145/255.f blue:153/255.f alpha:0.5f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = 8.f;
    self.layer.shadowOffset = CGSizeMake(0, 4.f);
    
    [self setNeedsDisplay];
}

#pragma mark - Actions

- (IBAction)didTapPreviousArticle:(UIButton *)sender {
    
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
    
    UIScrollView *scrollView = (UIScrollView *)[[self.superview subviews] firstObject];
//    CGSize contentSize = [scrollView contentSize];
    
//    sender.enabled = NO;
//    self.endOfArticle.enabled = YES;
    
    asyncMain(^{
        [scrollView setContentOffset:CGPointMake(0, -scrollView.adjustedContentInset.top) animated:YES];
    });
    
}

- (IBAction)didTapArticleEnd:(UIButton *)sender {
    
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
