//
//  PreviewLinesVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "PreviewLinesVC.h"
#import <DZTextKit/YetiConstants.h>
#import "YetiThemeKit.h"
#import "PrefsManager.h"

#define reuseIdentifer @"previewLinesCell"

@interface PreviewLinesVC ()

@property (assign) NSInteger selected;

@end

@implementation PreviewLinesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Preview";
    self.selected = SharedPrefs.previewLines;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:reuseIdentifer];
    
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifer forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.row == 0) {
        cell.textLabel.text = @"None";
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = @"1 Line";
    }
    else {
        cell.textLabel.text = formattedString(@"%@ Lines", @(indexPath.row));
    }
    
    if (self.selected == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    cell.backgroundColor = theme.backgroundColor;
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    if (cell.accessoryView != nil) {
        cell.accessoryView = nil;
    }
    
    return cell;
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    {
        NSIndexPath *selected = [NSIndexPath indexPathForRow:self.selected inSection:0];
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:selected];
        
        selectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selected = indexPath.row;
    
    [SharedPrefs setValue:@(self.selected) forKey:propSel(previewLines)];
    
}

@end
