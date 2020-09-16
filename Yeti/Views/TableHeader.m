//
//  TableHeader.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "TableHeader.h"
#import "YetiThemeKit.h"

@implementation TableHeader

- (void)didMoveToSuperview {
    if (self.superview) {
        self.backgroundColor = UIColor.systemBackgroundColor;
    }
}

#pragma mark - Setters
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.label.backgroundColor = backgroundColor;
    self.imageView.backgroundColor = backgroundColor;
}

@end
