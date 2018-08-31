//
//  MiscVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MiscVC.h"
#import "YetiThemeKit.h"

NSString *const kMiscSettingsCell = @"settingsCell";

@interface MiscVC ()

@end

@implementation MiscVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Miscellaneous";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMiscSettingsCell];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"App Icon";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMiscSettingsCell forIndexPath:indexPath];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
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

@end
