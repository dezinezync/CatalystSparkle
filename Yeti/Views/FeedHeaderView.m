//
//  FeedHeaderView.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedHeaderView.h"
#import "Feed.h"

#import <DZTextKit/NSString+HTML.h>
#import "YetiThemeKit.h"

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZAppdelegate/UIApplication+KeyWindow.h>

@interface FeedHeaderView () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;

@property (weak, nonatomic) Feed *feed;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *authorsFade;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;

@end

@implementation FeedHeaderView

- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        self.autoresizingMask = UIViewAutoresizingNone;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    for (UIView *subview in self.stackView.arrangedSubviews) {
        if ([subview isKindOfClass:UIButton.class]) {
            [self.stackView removeArrangedSubview:subview];
            [subview removeFromSuperview];
        }
    }
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.contentInset = UIEdgeInsetsMake(0, 16.f, 0, 16.f);
    self.scrollView.delegate = self;
    
    [self setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
    [self setupAppearance];
}

- (void)setupAppearance {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.backgroundColor = theme.cellColor;
    
    NSString *imageName = formattedString(@"authorsfade-%@", theme.name);
    UIImage *image = [UIImage imageNamed:imageName];
    
    self.authorsFade.image = image;
    
    self.descriptionLabel.backgroundColor = theme.cellColor;
    self.descriptionLabel.textColor = theme.subtitleColor;
    self.scrollView.backgroundColor = theme.cellColor;
    self.authorLabel.textColor = theme.titleColor;
    self.authorLabel.backgroundColor = theme.cellColor;
    
    if (self.feed) {
        [self configure:self.feed];
    }
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        
        [self.widthAnchor constraintEqualToAnchor:self.superview.widthAnchor multiplier:1.f].active = YES;
        [self.topAnchor constraintEqualToAnchor:self.superview.topAnchor].active = YES;
    }
    
}

- (void)configure:(Feed *)feed
{
    
    if (!feed)
        return;
    
    _feed = feed;
    
    NSString *summary = feed.summary ?: feed.extra.summary;
    summary = [summary htmlToPlainText];
    
    UIFont *font = nil;
    
    if ([UIApplication.keyWindow rootViewController].traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    else {
        font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }
    
    if (summary && [summary stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length != 0) {

        self.descriptionLabel.text = summary;
        [self.descriptionLabel sizeToFit];
        
    }
    else {
        
        self.descriptionLabel.hidden = YES;
        
    }
    
    if ([self.stackView arrangedSubviews].count) {
        
        for (UIView *subview in self.stackView.arrangedSubviews) {
            if ([subview isKindOfClass:UIButton.class]) {
                [self.stackView removeArrangedSubview:subview];
                [subview removeFromSuperview];
            }
        }
        
    }
    
    if (self.feed.authors != nil && self.feed.authors.count) {
        
        for (Author *author in self.feed.authors) { @autoreleasepool {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:author.name forState:UIControlStateNormal];
            [button addTarget:self action:@selector(didTapAuthorButton:) forControlEvents:UIControlEventTouchUpInside];
            
            button.titleLabel.font = font;
            button.titleLabel.adjustsFontForContentSizeCategory = YES;
            
            [button sizeToFit];
            
            [self.stackView addArrangedSubview:button];
        } }
        
    }
    else {
        self.scrollView.hidden = YES;
    }
    
    [self.stackView setNeedsUpdateConstraints];
    [self.stackView layoutIfNeeded];
    
    if ([self.scrollView isHidden] == NO) {
        
        self.scrollView.contentSize = [self.stackView sizeThatFits:CGSizeMake(self.bounds.size.width-32.f, CGFLOAT_MAX)];
        
        [self scrollViewDidScroll:self.scrollView];
        
    }
    
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    
    size.height = MAX(0, size.height);
    
    size.width = self.bounds.size.width - 32.f;
    
    if (self.descriptionLabel.isHidden == NO) {
        
        size.height += [self.descriptionLabel sizeThatFits:CGSizeMake(size.width, CGFLOAT_MAX)].height;
        
    }
    
    if (self.scrollView.isHidden == NO) {
        
        size.height += [self.stackView sizeThatFits:CGSizeMake(size.width, CGFLOAT_MAX)].height;
        
    }
    
    if (self.scrollView.isHidden == NO || self.descriptionLabel.isHidden == NO) {
        
        size.height += 24.f;
        
    }
    
    return size;
}

- (void)setShadowImage:(UIImageView *)shadowImage
{
    if (_shadowImage) {
        [_shadowImage removeFromSuperview];
        _shadowImage = nil;
    }
    
    if (shadowImage) {
        
        if ([shadowImage isHidden]) {
            shadowImage.hidden = NO;
        }
        
        UIImageView *copy = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIImageView class] fromData:[NSKeyedArchiver archivedDataWithRootObject:shadowImage requiringSecureCoding:NO error:nil] error:nil];
        copy.hidden = NO;
        copy.alpha = 1.f;
        copy.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:copy];
        
        [copy.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
        [copy.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        [copy.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-copy.bounds.size.height].active = YES;
        [copy.heightAnchor constraintEqualToConstant:copy.bounds.size.height].active = YES;
        
        _shadowImage = copy;
    }
    else {
        _shadowImage = shadowImage;
    }
}

#pragma mark - Actions

- (void)didTapAuthorButton:(UIButton *)button {
    
    NSString *name = [[button titleLabel] text];
    
    Author *author = [self.feed.authors rz_reduce:^id(Author *prev, Author *current, NSUInteger idx, NSArray *array) {
        if ([current.name isEqualToString:name])
            return current;
        return prev;
    }];
    
    if (!author)
        return;
    
//    DDLogDebug(@"Author: %@", author);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapAuthor:)]) {
        [self.delegate didTapAuthor:author];
    }
    
}

#pragma mark - A11Y

- (BOOL)isAccessibilityElement
{
    return NO;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat alpha = 1.f;
    CGFloat xPoint = scrollView.contentOffset.x + scrollView.contentInset.left;
    
    if (xPoint < scrollView.contentInset.left) {
        alpha = 0.f;
    }
    else {
        alpha = MIN(1.f, xPoint/(self.authorsFade.bounds.size.width * 2.f));
    }
    
//    DDLogDebug(@"x:%@", @(xPoint));
    self.authorsFade.alpha = alpha;
}

@end
