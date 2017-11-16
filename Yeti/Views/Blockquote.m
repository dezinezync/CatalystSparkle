//
//  Blockquote.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Blockquote.h"
#import "Paragraph.h"

@interface BlockPara : Paragraph

@end

@implementation BlockPara

- (CGSize)contentSize
{
    CGSize size = [super contentSize];
    size.height = [self.attributedText boundingRectWithSize:CGSizeMake(size.width - 32.f, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin context:nil].size.height + 12.f;
    
    return size;
}

- (UIFont *)font
{
    UIFont *base = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFontDescriptor *desc = base.fontDescriptor;
    desc = [desc fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    
    return [UIFont fontWithDescriptor:desc size:base.pointSize];
}


- (UIColor *)textColor
{
    return [[UIColor blackColor] colorWithAlphaComponent:0.54f];
}

@end

@interface Blockquote ()

@property (nonatomic, weak) BlockPara *textView;

@end

@implementation Blockquote

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
     
        UIImageView *decorator = [[UIImageView alloc] initWithFrame:CGRectMake(8.f, 12.f, 17.f, 12.61f)];
        decorator.image = [UIImage imageNamed:@"quote-decorator"];
        decorator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        
        [self addSubview:decorator];
        
        BlockPara *textview = [[BlockPara alloc] initWithFrame:CGRectMake(42.f, 0, frame.size.width - 42.f, frame.size.height - 16.f)];
        
        [self addSubview:textview];
        _textView = textview;
    }
    
    return self;
}

- (void)setText:(NSString *)text ranges:(NSArray<Range *> *)ranges
{
    [self.textView setText:text ranges:ranges];
    CGSize size = self.textView.contentSize;
    CGRect frame = CGRectMake(42.f, 0, size.width, size.height);
    
    self.textView.frame = frame;
    
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.textView contentSize];
    size.width += 42.f;
    size.height -= 32.f;
    
    return size;
}

@end
