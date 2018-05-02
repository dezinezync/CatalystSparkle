//
//  ThemeVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 30/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ThemeVC.h"
#import "YetiConstants.h"
#import "AppDelegate.h"

#import "YetiThemeKit.h"

NSString *const kSwitchCell = @"cell.switch";
NSString *const kCheckmarkCell = @"cell.checkmark";

@interface ThemeVC ()

@end

@implementation ThemeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Appearance";
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kSwitchCell];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCheckmarkCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"App wide";
    else if (section == 1)
        return @"Article Font";
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 2;
    }
    
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        // THEME
        cell = [tableView dequeueReusableCellWithIdentifier:kCheckmarkCell forIndexPath:indexPath];
        
        YetiThemeType theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
        
        cell.textLabel.text = indexPath.row == 0 ? @"Light" : @"Dark";
        
        if (([theme isEqualToString:LightTheme] && indexPath.row == 0)
            || ([theme isEqualToString:DarkTheme] && indexPath.row == 1)) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    else if (indexPath.section == 1) {
        // ARTICLE FONT
        cell = [tableView dequeueReusableCellWithIdentifier:kCheckmarkCell forIndexPath:indexPath];
        
        ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
        
        cell.textLabel.text = [[(indexPath.row == 0 ? ALPSystem : ALPSerif) stringByReplacingOccurrencesOfString:@"articlelayout." withString:@""] capitalizedString];
        
        if (([fontPref isEqualToString:ALPSystem] && indexPath.row == 0)
            || ([fontPref isEqualToString:ALPSerif] && indexPath.row == 1)) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (indexPath.section == 0) {
        
        NSString *val = indexPath.row == 0 ? LightTheme : DarkTheme;
        
        [defaults setValue:val forKey:kDefaultsTheme];
        
        if ([val isEqualToString:LightTheme]) {
            YTThemeKit.theme = [YTThemeKit themeNamed:@"light"];
        }
        else {
            YTThemeKit.theme = [YTThemeKit themeNamed:@"dark"];
        }
        
    }
    else if (indexPath.section == 1) {
        
        [defaults setValue:(indexPath.row == 0 ? ALPSystem : ALPSerif) forKey:kDefaultsArticleFont];
        
    }
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    
    [defaults synchronize];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        [self.settingsDelegate didChangeSettings];
    }
}

@end
