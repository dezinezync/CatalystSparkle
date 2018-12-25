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

#import <DZKit/UIViewController+AnimatedDeselect.h>

NSString *const kMiscSettingsCell = @"settingsCell";

@interface MiscVC () {
    BOOL _showingPreview;
}

@property (nonatomic, strong) NSArray <NSString *> *sections;

@end

@implementation MiscVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Miscellaneous";
    
    self.sections = @[@"App Icon", @"Unread Counters", @"Mark Read Prompt", @"Hide Bookmarks", @"Open Unread", @"Preview"];
    
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
        return 3;
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
    
    if (section == 3) {
        return @"You can optionally hide the Bookmarks Tab from the Feeds Interface.";
    }
    
    else if (section == 4) {
        return @"When this setting is enabled, the app will open the Unread Interface upon launch.";
    }
    
    else if (section == 5) {
        return @"Number of summary lines to show when viewing list of Articles.";
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
    
    NSString *sectionName = [self.sections objectAtIndex:indexPath.section];
    
    if ([sectionName isEqualToString:@"Mark Read Prompt"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:[defaults boolForKey:kShowMarkReadPrompt]];
        [sw addTarget:self action:@selector(didChangeMarkReadPromptPreference:) forControlEvents:UIControlEventValueChanged];
    }
    else if ([sectionName isEqualToString:@"Unread Counters"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:[defaults boolForKey:kShowUnreadCounts]];
        [sw addTarget:self action:@selector(didChangeUnreadCountsPreference:) forControlEvents:UIControlEventValueChanged];
    }
    else  if ([sectionName isEqualToString:@"Hide Bookmarks"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:[defaults boolForKey:kHideBookmarksTab]];
        [sw addTarget:self action:@selector(didChangeBookmarksPref:) forControlEvents:UIControlEventValueChanged];
    }
    else  if ([sectionName isEqualToString:@"Open Unread"]) {
        cell.textLabel.text = sectionName;
        
        [sw setOn:[defaults boolForKey:kOpenUnreadOnLaunch]];
        [sw addTarget:self action:@selector(didChangeUnreadPref:) forControlEvents:UIControlEventValueChanged];
    }
    
    if ([sectionName isEqualToString:@"Preview"]) {
        cell.textLabel.text = sectionName;
        
        cell.detailTextLabel.text = [self previewLinesText];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.accessoryView = sw;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
        
}

#pragma mark -

- (NSString *)previewLinesText {
    NSInteger lines = [[NSUserDefaults standardUserDefaults] integerForKey:kPreviewLines];
    
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

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1) {
        return;
    }
    
    // preview lines
    if (indexPath.section == 5) {
        
        _showingPreview = YES;
        
        PreviewLinesVC *vc = [[PreviewLinesVC alloc] initWithStyle:UITableViewStylePlain];
        
        [self.navigationController pushViewController:vc animated:YES];
        
        return;
    }
    
    if (indexPath.section == 0) {
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
    
}

#pragma mark - Actions

- (void)didChangeUnreadCountsPreference:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kShowUnreadCounts];
    [defaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:ShowUnreadCountsPreferenceChanged object:nil];
    });
    
}

- (void)didChangeMarkReadPromptPreference:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kShowMarkReadPrompt];
    [defaults synchronize];
    
}

- (void)didChangeBookmarksPref:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kHideBookmarksTab];
    [defaults synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:ShowBookmarksTabPreferenceChanged object:nil];
    });
    
}

- (void)didChangeUnreadPref:(UISwitch *)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn forKey:kOpenUnreadOnLaunch];
    [defaults synchronize];
    
}


@end
