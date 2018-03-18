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
NSString *const kExternalAppsCell = @"com.yeti.cell.externalApps";

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

@implementation ExternalAppsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.imageView.layer.cornerRadius = 6.5f;
        self.imageView.layer.masksToBounds = YES;
    }
    
    return self;
}

@end

