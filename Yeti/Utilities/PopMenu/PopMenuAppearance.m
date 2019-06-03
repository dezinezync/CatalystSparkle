//
//  PopMenuAppearance.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PopMenuAppearance.h"

@implementation PopMenuPresentationStyle

- (instancetype)init {
    
    if (self = [super init]) {
        self.direction = PopMenuDirectionNone;
        self.offset = CGPointZero;
    }
    
    return self;
    
}

- (instancetype)initNear:(CGPoint)point direction:(PopMenuDirection)direction {
    
    if (self = [super init]) {
        self.offset = point;
        self.direction = direction;
    }
    
    return self;
    
}

@end

@implementation PopMenuAppearance

- (instancetype)init {
    
    if (self = [super init]) {
        self.popMenuColor = [UIColor whiteColor];
        
        self.popMenuBackgroundColor = [UIColor colorWithWhite:0.f alpha:0.12f];
        
        self.popMenuFont = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        self.popMenuCornerRadius = 24.f;
        self.popMenuActionHeight = 50.f;
        self.popMenuActionCountForScrollable = 6;
        self.popMenuScrollIndicatorStyle = UIScrollViewIndicatorStyleDefault;
        self.popMenuScrollIndicatorHidden = NO;
        self.popMenuStatusBarStyle = UIStatusBarStyleDefault;
        
        self.popMenuPresentationStyle = [PopMenuPresentationStyle new];
    }
    
    return self;
    
}

@end
