//
//  Code.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "Code.h"
#import "UIColor+HEX.h"
#import "PaddedLabel.h"

#import "YetiThemeKit.h"

@interface Code ()

@property (nonatomic, strong) NSLayoutConstraint *labelWidth;

@end

@implementation Code

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
//        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
//        
//        self.backgroundColor = theme.articleBackgroundColor;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.clipsToBounds = NO;
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.alwaysBounceHorizontal = YES;
        scrollView.scrollEnabled = YES;
        scrollView.alwaysBounceVertical = NO;
        scrollView.clipsToBounds = NO;
        scrollView.contentInset = UIEdgeInsetsMake(LayoutPadding, LayoutPadding, 0, LayoutPadding);
        scrollView.opaque = YES;
        
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:scrollView];
        
        [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-LayoutImageMargin].active = YES;
        [scrollView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:(LayoutImageMargin * 2)].active = YES;
        [scrollView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
        [scrollView.heightAnchor constraintEqualToAnchor:self.heightAnchor constant:0].active = YES;
        
        PaddedLabel *label = [[PaddedLabel alloc] initWithFrame:scrollView.bounds];
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.padding = UIEdgeInsetsMake(0, 8.f, 0, 8.f);
        label.opaque = YES;
        
        [scrollView addSubview:label];
        
        [label.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:0.f].active = YES;
        [label.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:0.f].active = YES;
        
        _label = label;
        
        _scrollView = scrollView;
    }
    
    return self;
}

#pragma mark - Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    
    [super setBackgroundColor:backgroundColor];
    
    self.scrollView.backgroundColor = backgroundColor;

    for (UIView *view in self.scrollView.subviews) {
        view.backgroundColor = backgroundColor;
    }
    
}

- (NSString *)accessibilityLabel {
    return @"Code block";
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeZero;
    size.width = self.bounds.size.width;
    size.height = self.scrollView.contentSize.height + (LayoutPadding * 2);

    return size;
}

- (void)setAttributedText:(NSAttributedString *)attrs {
    self.label.attributedText = attrs;
    [self.label sizeToFit];
    
    CGSize contentSize = [self.label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    
    // accomodate label padding
    contentSize.width += 16.f;
    // add height of 1 line.
//    contentSize.height += [[self.label font] pointSize];
    
    self.scrollView.contentSize = contentSize;
    
    if (self.labelWidth) {
        self.labelWidth.active = NO;
        self.labelWidth = nil;
    }
    
    self.labelWidth = [self.label.widthAnchor constraintEqualToConstant:self.scrollView.contentSize.width];
    self.labelWidth.active = YES;
    
    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView setNeedsLayout];
    
    [self invalidateIntrinsicContentSize];
    
    for (UIView *subview in self.scrollView.subviews) {
        subview.backgroundColor = self.backgroundColor;
    }
}

@end
