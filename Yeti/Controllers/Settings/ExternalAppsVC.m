//
//  ExternalAppsVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ExternalAppsVC.h"
#import "SettingsCell.h"
#import "YetiConstants.h"
#import "YetiThemeKit.h"

@interface ExternalAppsVC ()

@property (nonatomic, strong) NSArray <NSString *> *twitterApps;
@property (nonatomic, strong) NSArray <NSString *> *redditApps;
@property (nonatomic, strong) NSArray <NSString *> *browserApps;

@end

@implementation ExternalAppsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"External Apps";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    [self.tableView registerClass:ExternalAppsCell.class forCellReuseIdentifier:kExternalAppsCell];
    
    self.tableView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIColor.secondarySystemGroupedBackgroundColor;
        }
        else {
            return UIColor.systemGroupedBackgroundColor;
        }
        
    }];
    
    UIApplication *app = [UIApplication sharedApplication];
    
    /**
     * SETUP ORDER
     * ** TWITTER **
     * - Tweetbot
     * - Twitterrific
     * - Twitter (Default)
     *
     * ** REDDIT **
     * - Alien Blue
     * - Antenna
     * - Apollo
     * - Reddit (Default)
     *
     * ** BROWSER **
     * - Safari (Default)
     * - Chrome
     * - Firefox
     */
    NSMutableArray *twitter = [NSMutableArray arrayWithCapacity:3];
    
    if ([app canOpenURL:[NSURL URLWithString:@"tweetbot://"]])
        [twitter addObject:@"Tweetbot"];
    if ([app canOpenURL:[NSURL URLWithString:@"twitterrific://"]])
        [twitter addObject:@"Twitterrific"];
    if ([app canOpenURL:[NSURL URLWithString:@"twitter://"]])
        [twitter addObject:@"Twitter"];
    
    self.twitterApps = twitter.copy;
    
    NSMutableArray *browsers = [NSMutableArray arrayWithCapacity:3];
    [browsers addObject:@"Safari"];
    
    if ([app canOpenURL:[NSURL URLWithString:@"googlechrome://"]])
        [browsers addObject:@"Chrome"];
    if ([app canOpenURL:[NSURL URLWithString:@"firefox://"]])
        [browsers addObject:@"Firefox"];
    
    self.browserApps = browsers.copy;
    
    NSMutableArray *reddit = [NSMutableArray arrayWithCapacity:4];
    
    if ([app canOpenURL:[NSURL URLWithString:@"alienblue://"]])
        [reddit addObject:@"Alien Blue"];
    if ([app canOpenURL:[NSURL URLWithString:@"antenna://"]])
        [reddit addObject:@"Antenna"];
    if ([app canOpenURL:[NSURL URLWithString:@"apollo://"]])
        [reddit addObject:@"Apollo"];
    if ([app canOpenURL:[NSURL URLWithString:@"narwhal://"]]) {
        [reddit addObject:@"Narwhal"];
    }
    if ([app canOpenURL:[NSURL URLWithString:@"reddit://"]])
        [reddit addObject:@"Reddit"];
    
    self.redditApps = reddit.copy;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 1:
            return @"Reddit";
            break;
        case 2:
            return @"Browser";
            break;
        default:
            return @"Twitter";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return self.redditApps.count;
            break;
        case 2:
            return self.browserApps.count;
            break;
        default:
            return self.twitterApps.count;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kExternalAppsCell forIndexPath:indexPath];
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [[self.view tintColor] colorWithAlphaComponent:0.3f];
    
    NSArray <NSString *> * appsArray = nil;
    NSString *sectionKey;
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            appsArray = self.twitterApps;
            sectionKey = ExternalTwitterAppScheme;
            break;
        case 1:
            appsArray = self.redditApps;
            sectionKey = ExternalRedditAppScheme;
            break;
        default:
            appsArray = self.browserApps;
            sectionKey = ExternalBrowserAppScheme;
            break;
    }
    
    NSString *title = appsArray[indexPath.row];
    NSString *appicon = [[[title componentsSeparatedByString:@" "] componentsJoinedByString:@""] lowercaseString];
    UIImage *image = [UIImage imageNamed:appicon];
    
    NSString *defaultsValue = [NSUserDefaults.standardUserDefaults stringForKey:sectionKey];
    if (defaultsValue && [defaultsValue isEqualToString:title])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.textLabel.text = title;
    cell.imageView.image = image;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSArray <NSString *> * appsArray = nil;
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            appsArray = self.twitterApps;
            break;
        case 1:
            appsArray = self.redditApps;
            break;
        default:
            appsArray = self.browserApps;
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:appsArray.count <= 1];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *title = [[[tableView cellForRowAtIndexPath:indexPath] textLabel] text];
    
    switch (indexPath.section) {
        case 0:
            [defaults setValue:title forKey:ExternalTwitterAppScheme];
            break;
        case 1:
            [defaults setValue:title forKey:ExternalRedditAppScheme];
            break;
        default:
            [defaults setValue:title forKey:ExternalBrowserAppScheme];
            break;
    }
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
    [tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
    
    [defaults synchronize];
}

@end
