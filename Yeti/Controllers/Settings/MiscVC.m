//
//  MiscVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MiscVC.h"
#import "SettingsCell.h"
#import "YetiConstants.h"
#import "PreviewLinesVC.h"
#import "PrefsManager.h"

#import <DZKit/NSArray+Safe.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

#import "Elytra-Swift.h"

NSString *const kMiscSettingsCell = @"settingsCell";

@interface MiscVC () {
    BOOL _showingPreview;
    NSArray <NSString *> * _appIconNames;
}

@property (nonatomic, strong) NSArray <NSString *> *sections;
@property (nonatomic, strong, readonly) NSArray <NSString *> * appIconNames;

@end

typedef NS_ENUM(NSInteger, AppIconName) {
    AppIconLight = 0,
    AppIconDark,
    AppIconBlack,
    AppIconRed,
    AppIconRedDark,
    AppIconGold,
    AppIconGoldDark,
    AppIconPlatinum,
    AppIconPlatinumDark,
    AppIconLastIndex
};

@implementation MiscVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Miscellaneous";
#if TARGET_OS_MACCATALYST
    self.sections = @[@"Unread Counters", @"Mark Read Prompt", @"Hide Bookmarks", @"Open Unread", @"Preview", @"Use Toolbar", @"Hide Bars"];
#else
    self.sections = @[@"App Icon", @"Unread Counters", @"Mark Read Prompt", @"Hide Bookmarks", @"Open Unread", @"Preview", @"Use Toolbar", @"Hide Bars", @"Reader Mode"];
#endif
    
    [self.tableView registerClass:SettingsBaseCell.class forCellReuseIdentifier:kMiscSettingsCell];
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
    [self.tableView registerClass:DeactivateCell.class forCellReuseIdentifier:kDeactivateCell];
    
    self.tableView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIColor.secondarySystemGroupedBackgroundColor;
        }
        else {
            return UIColor.systemGroupedBackgroundColor;
        }
        
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (_showingPreview == YES) {
        _showingPreview = NO;
        
        [self dz_smoothlyDeselectRows:self.tableView];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:5];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        cell.detailTextLabel.text = [self previewLinesText];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#if !TARGET_OS_MACCATALYST
    if (section == 0) {
        return AppIconLastIndex;
    }
#endif
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
#if !TARGET_OS_MACCATALYST
    if (section == 0) {
        return @"App Icon";
    }
#endif
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    
    if (section == 1) {
        return @"Set whether you want to see the number of unread articles in each section.";
    }
    
    if (section == 2) {
        return @"Set whether the app should prompt you when marking articles as read.";
    }
    
    if (section == 3) {
        return @"You can optionally hide the Bookmarks Tab from the Feeds Interface.";
    }
    
    else if (section == 4) {
        return @"When this setting is enabled, the app will open the Unread Interface upon launch.";
    }
    
    else if (section == 5) {
        return @"Number of summary lines to show when viewing list of Articles.";
    }
    
    else if (section == 6) {
        return @"Show all actions in toolbar at the bottom of the interface instead of the navigation bar at the top. (Requires an App restart)";
    }
    
    else if (section == 7) {
        return @"Hides the navigation bar and toolbar in the article reader when scrolling.";
    }
    
    else if (section == 7) {
        return @"You may enable reader mode for all feeds with a single tap.";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
#if !TARGET_OS_MACCATALYST
    if (indexPath.section == 0) {
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMiscSettingsCell forIndexPath:indexPath];
        
        cell.textLabel.textColor = UIColor.labelColor;
        
        cell.backgroundColor = UIColor.systemBackgroundColor;
        
        if (cell.selectedBackgroundView == nil) {
            cell.selectedBackgroundView = [UIView new];
        }
        
        cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
        
        NSString *selectedIcon = UIApplication.sharedApplication.alternateIconName;
        
        if (selectedIcon != nil) {
            selectedIcon = [selectedIcon stringByReplacingOccurrencesOfString:@"-" withString:@" "];
            selectedIcon = selectedIcon.capitalizedString;
        }
        
        NSInteger selected = selectedIcon == nil ? 0 : [self.appIconNames indexOfObject:selectedIcon];
        
        // Configure the cell...
        NSString *name = [self appIconNameForIndex:indexPath.row];
        
        if (name != nil) {
            cell.textLabel.text = [name stringByReplacingOccurrencesOfString:@"-" withString:@" - "];
        }
        
        cell.imageView.image = [UIImage imageNamed:name.lowercaseString];
        cell.imageView.contentMode = UIViewContentModeCenter;
        
        if (selected == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
        
        return cell;
    }
#endif
    SettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:kSettingsCell forIndexPath:indexPath];
    
    cell.textLabel.textColor = UIColor.labelColor;
    
    cell.backgroundColor = UIColor.systemBackgroundColor;
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
    
    UISwitch *sw = [[UISwitch alloc] init];
    
    NSString *sectionName = [self.sections objectAtIndex:indexPath.section];
    
    if ([sectionName isEqualToString:@"Mark Read Prompt"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.showMarkReadPrompts];
        [sw addTarget:self action:@selector(didChangeMarkReadPromptPreference:) forControlEvents:UIControlEventValueChanged];
    }
    else if ([sectionName isEqualToString:@"Unread Counters"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.showUnreadCounts];
        [sw addTarget:self action:@selector(didChangeUnreadCountsPreference:) forControlEvents:UIControlEventValueChanged];
    }
    else  if ([sectionName isEqualToString:@"Hide Bookmarks"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.hideBookmarks];
        [sw addTarget:self action:@selector(didChangeBookmarksPref:) forControlEvents:UIControlEventValueChanged];
    }
    else  if ([sectionName isEqualToString:@"Open Unread"]) {
        cell.textLabel.text = sectionName;
        
#if TARGET_OS_MACCATALYST
        [sw setOn:YES animated:NO];
        sw.enabled = NO;
#else
        [sw setOn:SharedPrefs.openUnread];
        [sw addTarget:self action:@selector(didChangeUnreadPref:) forControlEvents:UIControlEventValueChanged];
#endif
    }
    else if ([sectionName isEqualToString:@"Use Toolbar"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.useToolbar];
        [sw addTarget:self action:@selector(didChangeToolbarPref:) forControlEvents:UIControlEventValueChanged];
    }
    else if ([sectionName isEqualToString:@"Hide Bars"]) {
        
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.hideBars];
        [sw addTarget:self action:@selector(didChangeHideBarsPref:) forControlEvents:UIControlEventValueChanged];
        
    }
    
    [sw setOnTintColor:self.view.tintColor];
    
    if ([sectionName isEqualToString:@"Preview"]) {
        cell.textLabel.text = sectionName;
        
        cell.detailTextLabel.text = [self previewLinesText];
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([sectionName isEqualToString:@"Reader Mode"]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:kDeactivateCell forIndexPath:indexPath];
        
        cell.textLabel.text = @"Enable Reader Mode";
        cell.textLabel.textColor = SharedPrefs.tintColor;
        
    }
    else {
        cell.accessoryView = sw;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
        
}

#pragma mark -

- (NSString *)previewLinesText {
    NSInteger lines = SharedPrefs.previewLines;
    
    NSString *text = nil;
    
    if (lines == 0) {
        text = @"None";
    }
    else {
        if (lines == 1) {
            text = @"1 Line";
        }
        else {
            text = formattedString(@"%@ Lines", @(lines));
        }
    }
    
    return text;
}

- (NSString *)appIconNameForIndex:(NSInteger)index {
    
    NSString *name = [self.appIconNames safeObjectAtIndex:index];
    
    if (name != nil) {
        name = [name stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    }
    
    return name;
    
}

#pragma mark - Getters

- (NSArray <NSString *> *)appIconNames {
    if (_appIconNames == nil) {
        _appIconNames = @[@"Light", @"Dark", @"Black", @"Red", @"Red Dark", @"Gold", @"Gold Dark", @"Platinum", @"Platinum Dark"];
    }
    
    return _appIconNames;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        return;
    }
    
    // preview lines
    if (indexPath.section == 5) {
        
        _showingPreview = YES;
        
        UITableViewStyle style = UITableViewStyleInsetGrouped;
        
        PreviewLinesVC *vc = [[PreviewLinesVC alloc] initWithStyle:style];
        
        [self showViewController:vc sender:self];
        
        return;
    }
    
    // Reader Mode
    if (indexPath.section == 8) {
        
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Enable Reader Mode?" message:@"Are you sure you want to enable Reader Mode for all feeds?" preferredStyle:UIAlertControllerStyleAlert];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
//            @TODO:
            
//            [MyDBManager bulkUpdateFeedsAndMetadata:^FeedBulkOperation * _Nonnull(Feed * _Nonnull feed, NSMutableDictionary * _Nonnull metadata) {
//
//                metadata[kFeedSafariReaderMode] = @YES;
//
//                return [FeedBulkOperation withFeed:feed metadata:metadata];
//
//            }];
            
        }]];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        [self presentViewController:avc animated:YES completion:nil];
        
    }
    
    if (indexPath.section == 0) {
        NSString *name = indexPath.row == 0 ? nil : [self appIconNameForIndex:indexPath.row];
        
        if (name != nil) {
            name = name.lowercaseString;
        }
        
        [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError * _Nullable error) {
            
            if (error != nil) {
                NSLog(@"Set alternate icon error: %@", error);
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
    
}

#pragma mark - Actions

- (void)didChangeUnreadCountsPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(showUnreadCounts)];
    
}

- (void)didChangeMarkReadPromptPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(showMarkReadPrompts)];
    
}

- (void)didChangeBookmarksPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(hideBookmarks)];
    
}

- (void)didChangeUnreadPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(openUnread)];
    
}

- (void)didChangeToolbarPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(useToolbar)];
    
}

- (void)didChangeHideBarsPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(hideBars)];
    
}

@end
