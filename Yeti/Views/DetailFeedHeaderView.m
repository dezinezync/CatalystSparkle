//
//  DetailFeedHeaderView.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedHeaderView.h"

NSString *const kDetailFeedHeaderView = @"com.yeti.detailfeed.header";

@implementation DetailFeedHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
    
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
    
}

- (void)setup {
    FeedHeaderView *view = [[FeedHeaderView alloc] initWithNib];
    view.frame = self.bounds;
    
    [self addSubview:view];
    self.headerContent = view;
    
    [self setupAppearance];
}

- (void)setupAppearance {
    
    [self.headerContent setupAppearance];
    self.backgroundColor = self.headerContent.backgroundColor;
    
}

@end
