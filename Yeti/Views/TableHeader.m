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
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        self.backgroundColor = theme.cellColor;
        
        self.label.textColor = theme.isDark ? theme.captionColor : theme.titleColor;
    }
}

#pragma mark - Setters
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.label.backgroundColor = backgroundColor;
    self.imageView.backgroundColor = backgroundColor;
}

@end
