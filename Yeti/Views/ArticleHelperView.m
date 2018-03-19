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
        
        for (UIButton *button in @[self.previousArticleButton, self.nextArticleButton, self.startOfArticle, self.endOfArticle]) {
            button.imageView.image = [button.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            button.translatesAutoresizingMaskIntoConstraints = NO;
        }
        
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
}

- (IBAction)didTapNextArticle:(UIButton *)sender {
}

- (IBAction)didTapArticleTop:(UIButton *)sender {
}

- (IBAction)didTapArticleEnd:(UIButton *)sender {
}

@end
