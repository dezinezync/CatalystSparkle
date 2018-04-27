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

@interface Code ()

@property (nonatomic, strong) NSLayoutConstraint *labelWidth;

@end

@implementation Code

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.clipsToBounds = NO;
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectInset(self.bounds, 0, LayoutPadding)];
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.alwaysBounceHorizontal = YES;
        scrollView.scrollEnabled = YES;
        scrollView.alwaysBounceVertical = NO;
        scrollView.clipsToBounds = NO;
        
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:scrollView];
        
        [scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-14.f].active = YES;
        [scrollView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:28.f].active = YES;
        [scrollView.topAnchor constraintEqualToAnchor:self.topAnchor constant:LayoutPadding].active = YES;
        [scrollView.heightAnchor constraintEqualToAnchor:self.heightAnchor constant:-LayoutPadding].active = YES;
        
        PaddedLabel *label = [[PaddedLabel alloc] initWithFrame:scrollView.bounds];
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.padding = UIEdgeInsetsMake(0, 8.f, 0, 8.f);
        
        [scrollView addSubview:label];
        
        [label.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:0.f].active = YES;
        [label.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:0.f].active = YES;
        
        _label = label;
        
        _scrollView = scrollView;
    }
    
    return self;
}

- (void)updateStyle:(id)animated {
    
    NSTimeInterval duration = animated ? 0.3 : 0;
    
    weakify(self);
    
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        self.backgroundColor = [UIColor colorFromHexString:@"#f8f8f8"];
        self.scrollView.backgroundColor = self.backgroundColor;
        self.label.backgroundColor = self.scrollView.backgroundColor;
    }];
    
}

- (CGSize)intrinsicContentSize
{
    CGSize size = CGSizeZero;
    size.width = self.bounds.size.width;
    size.height = self.scrollView.contentSize.height + (LayoutPadding * 2);

    return size;
}

- (void)setAttributedText:(NSAttributedString *)attrs
{
    self.label.attributedText = attrs;
    [self.label sizeToFit];
    
    [self updateStyle:nil];
    
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
}

@end
