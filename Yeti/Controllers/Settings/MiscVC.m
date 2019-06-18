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
#import "PreviewLinesVC.h"

#import <DZKit/NSArray+Safe.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

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
    AppIconReader,
    AppIconFlutter,
    AppIconFlutterDark,
    AppIconLastIndex
};

@implementation MiscVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Miscellaneous";
    
    self.sections = @[@"App Icon", @"Unread Counters", @"Mark Read Prompt", @"Hide Bookmarks", @"Open Unread", @"Show Tags", @"Preview", @"Use Toolbar"];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMiscSettingsCell];
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
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
    
    if (section == 0) {
        return AppIconLastIndex;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"App Icon";
    }
    
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
        return @"Set whether you want to see or hide tags from the list of Articles.";
    }
    
    else if (section == 6) {
        return @"Number of summary lines to show when viewing list of Articles.";
    }
    
    else if (section == 7) {
        return @"Show all actions in toolbar at the bottom of the interface instead of the navigation bar at the top. (Requires an App restart)";
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
        
        [sw setOn:SharedPrefs.openUnread];
        [sw addTarget:self action:@selector(didChangeUnreadPref:) forControlEvents:UIControlEventValueChanged];
    }
    else if ([sectionName isEqualToString:@"Show Tags"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.showTags];
        [sw addTarget:self action:@selector(didChangeTagsPref:) forControlEvents:UIControlEventValueChanged];
    }
    else if ([sectionName isEqualToString:@"Use Toolbar"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:SharedPrefs.useToolbar];
        [sw addTarget:self action:@selector(didChangeToolbarPref:) forControlEvents:UIControlEventValueChanged];
    }
    
    [sw setOnTintColor:self.view.tintColor];
    
    if ([sectionName isEqualToString:@"Preview"]) {
        cell.textLabel.text = sectionName;
        
        cell.detailTextLabel.text = [self previewLinesText];
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
        _appIconNames = @[@"Light", @"Dark", @"Black", @"Reader", @"Flutter", @"Flutter Dark"];
    }
    
    return _appIconNames;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        return;
    }
    
    // preview lines
    if (indexPath.section == 6) {
        
        _showingPreview = YES;
        
        PreviewLinesVC *vc = [[PreviewLinesVC alloc] initWithStyle:UITableViewStylePlain];
        
        [self showViewController:vc sender:self];
        
        return;
    }
    
    if (indexPath.section == 0) {
        NSString *name = [self appIconNameForIndex:indexPath.row];
        
        if (name == nil) {
            return;
        }
        
        name = name.lowercaseString;
        
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

- (void)didChangeTagsPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(showTags)];
    
}

- (void)didChangeToolbarPref:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(useToolbar)];
    
}

@end
