//
//  SettingsCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SettingsCell.h"

NSString *const kSettingsCell = @"com.yeti.cell.settings";
NSString *const kAccountsCell = @"com.yeti.cell.accounts";

@implementation SettingsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
        
    }
    
    return self;
}

@end

@implementation AccountsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.38f alpha:1.f];
    }
    
    return self;
}

@end

