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
#import "CodeParser.h"

#import <sys/utsname.h>

NSString *const kSwitchCell = @"cell.switch";
NSString *const kCheckmarkCell = @"cell.checkmark";

@interface ThemeVC () {
    BOOL _isPhoneX;
    NSArray <ArticleLayoutPreference> * _fonts;
    NSDictionary <ArticleLayoutPreference, NSString *> *_fontNamesMap;
}

@end

@implementation ThemeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Appearance";
    // when adding a new font here or removing one,
    // update the method -[tableview:cellForRowAtIndexPath:]
    _fonts = @[ALPSystem, ALPSerif, ALPHelvetica, ALPMerriweather, ALPPlexSerif, ALPPlexSans, ALPSpectral];
    _fontNamesMap = @{
                      ALPSystem : @"System (San Fransico)",
                      ALPSerif : @"Georgia",
                      ALPHelvetica : @"Helvetica Neue",
                      ALPMerriweather : @"Merriweather",
                      ALPPlexSerif : @"Plex Serif",
                      ALPPlexSans : @"Plex Sans",
                      ALPSpectral : @"Spectral"
                      };
    
    _isPhoneX = [[self modelIdentifier] isEqualToString:@"iPhone10,3"];
    
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
        return _isPhoneX ? 3 : 2;
    }
    
    return self->_fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        // THEME
        cell = [tableView dequeueReusableCellWithIdentifier:kCheckmarkCell forIndexPath:indexPath];
        
        YetiThemeType theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
        
        cell.textLabel.text = indexPath.row == 0 ? @"Light" : (indexPath.row == 1 ? @"Dark" : @"Black");
        
        if (([theme isEqualToString:LightTheme] && indexPath.row == 0)
            || ([theme isEqualToString:DarkTheme] && indexPath.row == 1)
            || ([theme isEqualToString:BlackTheme] && indexPath.row == 2)) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
    }
    else {//if (indexPath.section == 1) {
        // ARTICLE FONT
        cell = [tableView dequeueReusableCellWithIdentifier:kCheckmarkCell forIndexPath:indexPath];
        
        ArticleLayoutPreference fontPref = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsArticleFont];
        
        cell.textLabel.text = _fontNamesMap[_fonts[indexPath.row]];
        
        if (([fontPref isEqualToString:ALPSystem] && indexPath.row == 0)
            || ([fontPref isEqualToString:ALPSerif] && indexPath.row == 1)
            || ([fontPref isEqualToString:ALPHelvetica] && indexPath.row == 2)
            || ([fontPref isEqualToString:ALPMerriweather] && indexPath.row == 3)
            || ([fontPref isEqualToString:ALPPlexSerif] && indexPath.row == 4)
            || ([fontPref isEqualToString:ALPPlexSans] && indexPath.row == 5)
            || ([fontPref isEqualToString:ALPSpectral] && indexPath.row == 6)) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // Configure the cell...
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    cell.selectedBackgroundView = selected;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSIndexSet * reloadSections;
    
    if (indexPath.section == 0) {
        
        NSString *val = indexPath.row == 0 ? LightTheme : (indexPath.row == 1 ? DarkTheme : BlackTheme);
        
        [defaults setValue:val forKey:kDefaultsTheme];
        
        NSString *themeName = nil;
        if ([val isEqualToString:LightTheme]) {
            themeName = @"light";
        }
        else if ([val isEqualToString:BlackTheme]) {
            themeName = @"black";
        }
        else {
            themeName = @"dark";
        }
        
        YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
        [MyCodeParser loadTheme:themeName];
        
    }
    else if (indexPath.section == 1) {
        
        [defaults setValue:self->_fonts[indexPath.row] forKey:kDefaultsArticleFont];
        
        reloadSections = [NSIndexSet indexSetWithIndex:indexPath.section];
        
    }
    
    if (!reloadSections) {
        reloadSections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    }
    
    [tableView reloadSections:reloadSections withRowAnimation:UITableViewRowAnimationNone];
    
    [defaults synchronize];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        [self.settingsDelegate didChangeSettings];
    }
}

#pragma mark - Helpers

- (NSString *)modelIdentifier {
    
    NSString *simulatorModelIdentifier = [NSProcessInfo processInfo].environment[@"SIMULATOR_MODEL_IDENTIFIER"];
    NSLog(@"%@",simulatorModelIdentifier);
    
    if (simulatorModelIdentifier) {
        return simulatorModelIdentifier;
    }
    
    struct utsname sysInfo;
    uname(&sysInfo);
    
    return [NSString stringWithCString:sysInfo.machine encoding:NSUTF8StringEncoding];
}

@end
