//
//  List.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "List.h"
#import "Paragraph.h"

@interface List ()

@property (nonatomic, weak) UIStackView *stackView;

@end

@implementation List

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
     
        UIStackView *stackView = [[UIStackView alloc] initWithFrame:self.bounds];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.spacing = 16.f;
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.baselineRelativeArrangement = YES;
        
//        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:stackView];
        _stackView = stackView;
        
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [self.stackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size;
}

#pragma mark -

- (void)setContent:(Content *)content {
    
    self.type = [content.type isEqualToString:@"orderedList"] ? 1 : 0;
    
    for (Content *item in content.items) { @autoreleasepool {
        
        CGRect frame = CGRectMake(0, 0, self.stackView.bounds.size.width, 0.f);
        
        Paragraph *para = [[Paragraph alloc] initWithFrame:frame];
        [para setText:item.content ranges:item.ranges];
        
        frame.size.height = para.contentSize.height;
        para.frame = frame;
        
        [self.stackView addArrangedSubview:para];
        
    }}
    
    CGRect frame = self.stackView.frame;
    frame.size.height = [self.stackView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    self.stackView.frame = frame;
    
}

@end
