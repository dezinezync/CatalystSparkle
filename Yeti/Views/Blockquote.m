//
//  Blockquote.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Blockquote.h"
#import "LayoutConstants.h"

//@implementation BlockPara
//
//- (BOOL)avoidsLazyLoading
//{
//    return YES;
//}
//
//- (UIFont *)font
//{
//    UIFont *base = [super font];
//    UIFontDescriptor *desc = base.fontDescriptor;
//    desc = [desc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
//
//    return [UIFont fontWithDescriptor:desc size:base.pointSize];
//}
//
//- (UIColor *)textColor
//{
//    return [[UIColor blackColor] colorWithAlphaComponent:0.75f];
//}
//
//- (NSParagraphStyle *)paragraphStyle {
//    if (!_paragraphStyle) {
//        NSMutableParagraphStyle *style = [Paragraph paragraphStyle].mutableCopy;
//        style.lineBreakMode = NSLineBreakByWordWrapping;
//        style.headIndent = LayoutPadding;
//        style.firstLineHeadIndent = LayoutPadding;
//        style.tailIndent = -LayoutPadding;
//
//        _paragraphStyle = style;
//    }
//
//    return _paragraphStyle;
//}
//
//@end
//
//@interface Blockquote ()
//
//@property (nonatomic) NSLayoutConstraint *heightConstraint;
//@property (nonatomic, weak) UIView *decorator;
//
//@end
//
//@implementation Blockquote
//
//- (instancetype)initWithFrame:(CGRect)frame
//{
//    if (self = [super initWithFrame:frame]) {
//
//        self.opaque = YES;
//
//        self.layoutMargins = UIEdgeInsetsZero;
//
//        BlockPara *textview = [[BlockPara alloc] initWithFrame:self.bounds];
//        textview.translatesAutoresizingMaskIntoConstraints = NO;
//
//        [self addSubview:textview];
//
//        [textview.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0].active = YES;
//        [textview.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.f].active = YES;
//        [textview.topAnchor constraintEqualToAnchor:self.topAnchor constant:LayoutPadding/2.f].active = YES;
//        [self.bottomAnchor constraintEqualToAnchor:textview.bottomAnchor constant:0.f].active = YES;
//
//        _textView = textview;
//
//        UIImageView *decorator = [[UIImageView alloc] initWithFrame:CGRectMake(LayoutPadding/2.f, 0.f, 17.f, 12.61f)];
//        decorator.image = [UIImage imageNamed:@"quote-decorator"];
//        decorator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
//        decorator.opaque = YES;
//
//        [self addSubview:decorator];
//
//        [self updateStyle:nil];
//    }
//
//    return self;
//}
//
//- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges attributes:(NSDictionary *)attributes
//{
//    [self.textView setText:text ranges:ranges attributes:attributes];
//    [self updateFrame];
//}
//
//- (void)append:(NSAttributedString *)attrs
//{
//    NSMutableAttributedString *mattrs = [self.textView.attributedText mutableCopy];
//    [mattrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName : BlockPara.paragraphStyle}]];
//    [mattrs appendAttributedString:attrs];
//
//    self.textView.attributedText = mattrs;
//
//    [self.textView invalidateIntrinsicContentSize];
//    [self updateFrame];
//    [self invalidateIntrinsicContentSize];
//}
//
//- (void)updateFrame
//{
////    CGSize size = self.intrinsicContentSize;
////    CGRect frame = CGRectMake(24.f, 0, size.width, size.height - 12.f);
////
////    self.textView.frame = frame;
//}
//
//- (CGSize)intrinsicContentSize
//{
//    CGFloat width = self.bounds.size.width;
//    if (self.superview) {
//        width = self.superview.bounds.size.width;
//    }
//
//    width -= 24.f;
//
//    CGSize size = [self.textView sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
//    // remove 4 lines worth of height
//    size.height -= ([self.textView bodyFont].pointSize * 1.444f) * 4;
//    return size;
//}
//
//- (void)updateStyle:(id)animated {
//
//    NSTimeInterval duration = animated ? 0.3 : 0;
//
//    weakify(self);
//
//    [UIView animateWithDuration:duration animations:^{
//        strongify(self);
//        self.backgroundColor = UIColor.whiteColor;
//        self.decorator.backgroundColor = UIColor.whiteColor;
//    }];
//
//}
//
//@end

@interface Blockquote () {
    UIFont *_bodyFont;
    NSParagraphStyle *_paragraphStyle;
}

@property (nonatomic, weak) UIView *leftBorder;

@end

@implementation Blockquote

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.clipsToBounds = NO;
        
        UIView * leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2.f, self.bounds.size.height)];
        leftBorder.backgroundColor = [UIColor colorWithWhite:0.92f alpha:1.f];
        leftBorder.opaque = YES;
        leftBorder.translatesAutoresizingMaskIntoConstraints = NO;
        leftBorder.clipsToBounds = YES;
        leftBorder.layer.cornerRadius = 2.f;
        
        [self addSubview:leftBorder];
        
        _leftBorder = leftBorder;
        
        [_leftBorder.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:(LayoutPadding / -2.f)].active = YES;
        [_leftBorder.topAnchor constraintEqualToAnchor:self.topAnchor constant:(LayoutPadding / 2.f)].active = YES;
        [_leftBorder.widthAnchor constraintEqualToConstant:2.f].active = YES;
        [_leftBorder.heightAnchor constraintEqualToAnchor:self.heightAnchor constant: (LayoutPadding * -2.f)].active = YES;
        
    }
    
    return self;
}

#pragma mark - Getters

- (UIFont *)bodyFont {
    
    if (!_bodyFont) {
        UIFont *base = [super bodyFont];
        _bodyFont = [UIFont systemFontOfSize:(base.pointSize - 1.f)];
    }
    
    return _bodyFont;
    
}

- (UIColor *)textColor {
    return [UIColor colorWithWhite:0.18f alpha:1.f];
}

@end
