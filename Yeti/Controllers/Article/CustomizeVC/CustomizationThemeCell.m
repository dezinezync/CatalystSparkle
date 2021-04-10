//
//  CustomizationThemeCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "CustomizationThemeCell.h"
#import "YetiThemeKit.h"
#import "PrefsManager.h"
#import "CodeParser.h"

NSString * _Nonnull const kCustomizeThemeCell = @"com.dezinezync.elytra.cell.customizeTheme";

@interface CustomizationThemeCell () {
    NSUInteger _selectedIndex;
}

@end

@implementation CustomizationThemeCell

+ (void)registerOnTableView:(UITableView *)tableView {
    
    if (tableView == nil) {
        return;
    }
    
    [tableView registerNib:[UINib nibWithNibName:NSStringFromClass(self.class) bundle:nil] forCellReuseIdentifier:kCustomizeThemeCell];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _selectedIndex = NSNotFound;
    
    for (UIButton *button in @[self.defaultTheme, self.readerTheme, self.blackTheme]) {
     
        button.layer.cornerRadius = button.bounds.size.width/2.f;
        [button addTarget:self action:@selector(didTapButton:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    if (canSupportOLED() == NO) {
        self.blackTheme.hidden = YES;
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)didMoveToSuperview {
    
    [self updateTints];
    
}

- (void)updateTints {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        for (UIButton *button in @[self.defaultTheme, self.readerTheme, self.blackTheme]) {
         
            button.layer.borderColor = self.window.tintColor.CGColor;
            
        }
        
    });
    
}

- (void)didTapButton:(UIButton *)sender {
    
//    NSUInteger index = NSNotFound;
//    
//    if (sender == self.defaultTheme) {
//        index = 0;
//    }
//    else if (sender == self.readerTheme) {
//        index = 1;
//    }
//    else if (sender == self.blackTheme) {
//        index = 2;
//    }
//    
//    [self setActive:index];
//    
//    NSString *val = [YetiThemeKit.themeNames objectAtIndex:index];
//    
//    NSString *themeName = [val lowercaseString];
//    
//    if ([SharedPrefs.theme isEqualToString:themeName] == NO) {
//        
//        [SharedPrefs setValue:themeName forKey:propSel(theme)];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [NSNotificationCenter.defaultCenter postNotificationName:kWillUpdateTheme object:nil];
//        });
//        
//        YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
//        [CodeParser.sharedCodeParser loadTheme:themeName];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//            [NSNotificationCenter.defaultCenter postNotificationName:kDidUpdateTheme object:nil];
//            
//            [self updateTints];
//            
//        });
//        
//    }
    
}

- (void)setActive:(NSUInteger)index {
    
    if (_selectedIndex != NSNotFound) {
        
        if (_selectedIndex == 0) {
            self.defaultTheme.layer.borderWidth = 0;
        }
        else if (_selectedIndex == 1) {
            self.readerTheme.layer.borderWidth = 0;
        }
        else if (_selectedIndex == 2) {
            self.blackTheme.layer.borderWidth = 0;
        }
        
    }
    
    if (index == 0) {
        self.defaultTheme.layer.borderWidth = 2;
    }
    else if (index == 1) {
        self.readerTheme.layer.borderWidth = 2;
    }
    else if (index == 2) {
        self.blackTheme.layer.borderWidth = 2;
    }
    
    _selectedIndex = index;
    
}

@end
