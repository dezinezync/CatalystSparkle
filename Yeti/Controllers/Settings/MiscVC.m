//
//  MiscVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MiscVC.h"
#import "YetiThemeKit.h"
#import "SettingsCell.h"
#import "YetiConstants.h"

NSString *const kMiscSettingsCell = @"settingsCell";

@interface MiscVC ()

@end

@implementation MiscVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Miscellaneous";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMiscSettingsCell];
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return 3;
    }
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section != 0) {
        return 1;
    }
    
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section != 0) {
        return nil;
    }
    
    return @"App Icon";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1 && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return @"Extended Feed Layout was introduced in version 1.1 of the app and brings a the richer Feed Interface from the iPad on your iPhone and iPod Touch.";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMiscSettingsCell forIndexPath:indexPath];
        
        cell.textLabel.textColor = theme.titleColor;
        
        cell.backgroundColor = theme.cellColor;
        
        if (cell.selectedBackgroundView == nil) {
            cell.selectedBackgroundView = [UIView new];
        }
        
        cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
        
        NSString *selectedIcon = UIApplication.sharedApplication.alternateIconName;
        NSInteger selected = selectedIcon == nil ? 0 : ([selectedIcon isEqualToString:@"dark"] ? 1 : 2);
        
        // Configure the cell...
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Light";
                break;
            case 1:
                cell.textLabel.text = @"Dark";
                break;
            default:
                cell.textLabel.text = @"Black";
                break;
        }
        
        cell.imageView.image = [UIImage imageNamed:cell.textLabel.text.lowercaseString];
        cell.imageView.contentMode = UIViewContentModeCenter;
        
        if (selected == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.3f];
        
        return cell;
    }
    
    SettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:kSettingsCell forIndexPath:indexPath];
    
    cell.textLabel.textColor = theme.titleColor;
    
    cell.backgroundColor = theme.cellColor;
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    UISwitch *sw = [[UISwitch alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // on iPhones and iPod touches, we show an additional row
    if (indexPath.section == 1 && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        cell.textLabel.text = @"Extended Feed Layout";
        
        [sw setOn:[defaults boolForKey:kUseExtendedFeedLayout]];
        [sw addTarget:self action:@selector(didChangeExtendedLayoutPreference:) forControlEvents:UIControlEventValueChanged];
    }
    else {
        cell.textLabel.text = @"Unread Counters";
        
        [sw setOn:[defaults boolForKey:kShowUnreadCounts]];
        [sw addTarget:self action:@selector(didChangeUnreadCountsPreference:) forControlEvents:UIControlEventValueChanged];
    }
    
    cell.accessoryView = sw;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
        
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        return;
    }
    
    NSString *name = nil;
    
    switch (indexPath.row) {
        case 1:
            name = @"dark";
            break;
        case 2:
            name = @"black";
            break;
        default:
            break;
    }
    
    [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
        
        if (error != nil) {
            DDLogError(@"Set alternate icon error: %@", error);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
               
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                for (NSUInteger idx = 0, rows = [self.tableView numberOfRowsInSection:0]; idx < rows; idx++) { @autoreleasepool {
                    if (idx == indexPath.row) {
                        continue;
                    }
                    
                    NSIndexPath *otherIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                    cell = [tableView cellForRowAtIndexPath:otherIndexPath];
                    
                    cell.accessoryType = UITableViewCellAccessoryNone;
                } }
                
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        });
        
    }];
    
}

#pragma mark - Actions

- (void)didChangeExtendedLayoutPreference:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kUseExtendedFeedLayout];
    [defaults synchronize];
    
}

- (void)didChangeUnreadCountsPreference:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kShowUnreadCounts];
    [defaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:ShowUnreadCountsPreferenceChanged object:nil];
    });
    
}

@end
