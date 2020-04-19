//
//  AccountFooterView.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccountFooterView.h"
#import <DZTextKit/YetiThemeKit.h>

@implementation AccountFooterView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.backgroundColor = theme.tableColor;
    
    for (UIButton *button in @[self.learnButton, self.restoreButton]) {
        button.layer.cornerRadius = 4.f;
        button.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.25f];
    }
}

@end
