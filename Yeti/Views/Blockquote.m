//
//  Blockquote.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Blockquote.h"

@implementation BlockPara

- (UIFont *)font
{
    UIFont *base = [super font];
    UIFontDescriptor *desc = base.fontDescriptor;
    desc = [desc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    
    return [UIFont fontWithDescriptor:desc size:base.pointSize];
}

- (UIColor *)textColor
{
    return [[UIColor blackColor] colorWithAlphaComponent:0.54f];
}

- (NSParagraphStyle *)paragraphStyle {
    if (!_paragraphStyle) {
        NSMutableParagraphStyle *style = [Paragraph paragraphStyle].mutableCopy;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        
        _paragraphStyle = style;
    }
    
    return _paragraphStyle;
}

@end

@interface Blockquote ()

@property (nonatomic) NSLayoutConstraint *heightConstraint;
@property (nonatomic, weak) UIView *decorator;

@end

@implementation Blockquote

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        UIColor *white = UIColor.whiteColor;
        self.backgroundColor = white;
        self.opaque = YES;
        
        BlockPara *textview = [[BlockPara alloc] initWithFrame:self.bounds];
        textview.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:textview];
        
        [textview.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.f].active = YES;
        [textview.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.f].active = YES;
        [textview.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.f].active = YES;
        [self.bottomAnchor constraintEqualToAnchor:textview.bottomAnchor constant:-40.f].active = YES;
        
        _textView = textview;
        
        UIImageView *decorator = [[UIImageView alloc] initWithFrame:CGRectMake(8.f, 0.f, 17.f, 12.61f)];
        decorator.image = [UIImage imageNamed:@"quote-decorator"];
        decorator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        decorator.backgroundColor = white;
        decorator.opaque = YES;
        
        [self addSubview:decorator];
        
        [self updateStyle:nil];
    }
    
    return self;
}

- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges attributes:(NSDictionary *)attributes
{
    [self.textView setText:text ranges:ranges attributes:attributes];
    [self updateFrame];
}

- (void)append:(NSAttributedString *)attrs
{
    NSMutableAttributedString *mattrs = [self.textView.attributedText mutableCopy];
    [mattrs appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName : BlockPara.paragraphStyle}]];
    [mattrs appendAttributedString:attrs];
    
    self.textView.attributedText = mattrs;
    
    [self.textView invalidateIntrinsicContentSize];
    [self updateFrame];
    [self invalidateIntrinsicContentSize];
}

- (void)updateFrame
{
    CGSize size = self.textView.contentSize;
    CGRect frame = CGRectMake(42.f, 0, size.width, size.height);
    
    self.textView.frame = frame;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.textView intrinsicContentSize];
    // add image height and padding
    size.width = MIN(self.bounds.size.width, size.width + 25.f);
    size.height -= 24.f;
    return size;
}

- (void)updateStyle:(id)animated {
    
    NSTimeInterval duration = animated ? 0.3 : 0;
    
    weakify(self);
    
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        self.backgroundColor = UIColor.whiteColor;
        self.decorator.backgroundColor = UIColor.whiteColor;
    }];
    
}

@end
