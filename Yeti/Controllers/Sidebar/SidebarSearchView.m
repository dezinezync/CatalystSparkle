//
//  SidebarSearchView.m
//  Elytra
//
//  Created by Nikhil Nigade on 28/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarSearchView.h"

NSString *const kSidebarSearchView = @"sidebarSearchView";

@implementation SidebarSearchView

- (void)didAddSubview:(UIView *)subview {
    
    subview.frame = self.bounds;
    
    [super didAddSubview:subview];
    
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (self.subviews.count > 0) {
        
        self.subviews.firstObject.frame = self.bounds;
        
    }
    
}

@end
