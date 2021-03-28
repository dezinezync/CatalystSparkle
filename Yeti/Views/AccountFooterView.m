//
//  AccountFooterView.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccountFooterView.h"
#import "PrefsManager.h"

@implementation AccountFooterView

- (void)awakeFromNib {
    [super awakeFromNib];

    self.backgroundColor = UIColor.systemGroupedBackgroundColor;

    for (UIButton *button in @[self.learnButton, self.restoreButton]) {
        button.layer.cornerRadius = 4.f;
        button.backgroundColor = [SharedPrefs.tintColor colorWithAlphaComponent:0.25f];
    }
}

@end
