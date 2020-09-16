//
//  SettingsCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SettingsCell.h"
#import "YetiThemeKit.h"

NSString *const kSettingsCell = @"com.yeti.cell.settings";
NSString *const kAccountsCell = @"com.yeti.cell.accounts";
NSString *const kExternalAppsCell = @"com.yeti.cell.externalApps";
NSString *const kDeactivateCell = @"com.yeti.cell.deactivateCell";
NSString *const kStoreCell = @"com.yeti.cell.storeCell";

@implementation SettingsBaseCell

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    
    CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    
#if TARGET_OS_MACCATALYST
    size.height += 12.f;
#endif
    
    return size;
    
}

@end

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
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.textLabel.textColor = UIColor.secondaryLabelColor;
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

@implementation DeactivateCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        self.textLabel.textColor = UIColor.systemRedColor;
        self.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return self;
}

@end

@implementation StoreCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
        
        self.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.textLabel.textColor = UIColor.secondaryLabelColor;
        
        self.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        self.detailTextLabel.textColor = UIColor.labelColor;
        
    }
    
    return self;
}

@end

