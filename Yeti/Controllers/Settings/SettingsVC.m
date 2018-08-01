//
//  SettingsVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SettingsVC.h"
#import "SettingsCell.h"
#import "YetiConstants.h"
#import "UIColor+HEX.h"

#import "AccountVC.h"
#import "ImageLoadingVC.h"
#import "ExternalAppsVC.h"
#import "FiltersVC.h"
#import "ThemeVC.h"
#import "OPMLVC.h"

#import <DZKit/DZView.h>
#import "DZWebViewController.h"
#import <DZKit/UIViewController+AnimatedDeselect.h>

#import "YetiThemeKit.h"

@interface SettingsVC () <SettingsChanges> {
    BOOL _settingsUpdated;
    BOOL _hasAnimatedFooterView;
}

@property (nonatomic, strong) UIView *footerView;

@end

@implementation SettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Settings";
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow_down"] style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone)];
    done.accessibilityLabel = @"Close";
    done.accessibilityValue = @"Close settings";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationItem.rightBarButtonItem = done;
    
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    [self didUpdateTheme];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (_settingsUpdated) {
        _settingsUpdated = NO;
        
        [self.tableView reloadData];
    }
    
    if (!_hasAnimatedFooterView) {
        _hasAnimatedFooterView = YES;
        
        DZView *view = [self.footerView viewWithTag:30000];
        
        [view animate];
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[YTThemeKit theme] isDark] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark - Actions

- (void)didTapDone {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didChangeBackgroundRefreshPreference:(UISwitch *)sw {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sw.isOn forKey:@"backgroundRefresh"];
    [defaults synchronize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Account";
            break;
        case 1:
            return @"App";
            break;
        default:
            return @"About";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        case 2:
            return 3;
            break;
        default:
            return 5;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSettingsCell forIndexPath:indexPath];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Your Account";
                    break;
                    
                default:
                    cell.textLabel.text = @"Filters";
                    break;
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        case 1 :
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Appearance";
                    cell.detailTextLabel.text = [[defaults valueForKey:kDefaultsTheme] capitalizedString];
                }
                    break;
                case 1:
                {
                    cell.textLabel.text = @"Background Fetch";
                    
                    UISwitch *sw = [[UISwitch alloc] init];
                    [sw setOn:[defaults boolForKey:kDefaultsBackgroundRefresh]];
                    [sw addTarget:self action:@selector(didChangeBackgroundRefreshPreference:) forControlEvents:UIControlEventValueChanged];
                    
                    cell.accessoryView = sw;
                }
                    break;
                case 2: {
                    cell.textLabel.text = @"Image Loading";
                    cell.detailTextLabel.text = [defaults valueForKey:kDefaultsImageLoading];
                }
                    break;
                case 3:
                    cell.textLabel.text = @"External Apps";
                    break;
                case 4:
                    cell.textLabel.text = @"Import/Export OPML";
                    break;
                default:
                    break;
            }
            
            if (indexPath.row != 1 && indexPath.row != 5) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                // set the toggle
            }
            
            break;
        default:
            switch (indexPath.row) {
                case 0:
                {
                    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
                    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
                    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
                    
                    cell.textLabel.text = @"Elytra";
                    cell.detailTextLabel.text = formattedString(@"%@ (%@)", appVersion, buildNumber);
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                    break;
                case 2:
                    cell.textLabel.text = @"Attributions";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                default:
                    cell.textLabel.text = @"Rate";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }
    
    NSString *title = [[cell.textLabel.text lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    if ([title containsString:@"opml"]) {
        title = @"settings_opml";
    }
    if ([title containsString:@"background"]) {
        title = @"sync";
    }
    if ([title containsString:@"elytra"]) {
        title = @"settings_elytra";
    }
    
    UIImage *image = [UIImage imageNamed:title];
    
    cell.imageView.image = image;
    
    return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    
    UIViewController *vc;
    // vc = [[<#DetailViewController#> alloc] initWithNibName:NSStringFromClass(<#NSString * _Nonnull aClassName#>) bundle:nil];
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    vc = [[AccountVC alloc] initWithNibName:NSStringFromClass(AccountVC.class) bundle:nil];
                    break;
                    
                default:
                    vc = [[FiltersVC alloc] initWithStyle:UITableViewStyleGrouped];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                {
                    vc = [[ThemeVC alloc] initWithStyle:UITableViewStyleGrouped];
                }
                    break;
                case 2:
                {
                    vc = [[ImageLoadingVC alloc] initWithNibName:NSStringFromClass(ImageLoadingVC.class) bundle:nil];
                }
                    break;
                case 3:
                    vc = [[ExternalAppsVC alloc] initWithNibName:NSStringFromClass(ExternalAppsVC.class) bundle:nil];
                    break;
                case 4:
                    vc = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
                    break;
                default:
                    break;
            }
            break;
        default:
            if (indexPath.row == 2) {
                DZWebViewController *webVC = [[DZWebViewController alloc] init];
                webVC.title = @"Attributions";
                
                webVC.URL = [[NSBundle bundleForClass:self.class] URLForResource:@"attributions" withExtension:@"html"];
                
                Theme *theme = YTThemeKit.theme;
                
                if (![theme.name isEqualToString:@"light"]) {
                    NSString *tint = [UIColor hexFromUIColor:theme.tintColor];
                    NSString *js = formattedString(@"darkStyle(%@,\"%@\")", [YTThemeKit.theme.name isEqualToString:@"black"] ? @0 : @1, tint);
                    
                    webVC.evalJSOnLoad = js;
                }
                
                vc = webVC;
            }
            else if (indexPath.row == 1) {
                NSURL *URL = formattedURL(@"https://itunes.apple.com/app/id1173774272?action=write-review");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
                });
            }
            break;
    }
    
    if ([vc conformsToProtocol:@protocol(SettingsNotifier)]) {
        [(id<SettingsNotifier>)vc setSettingsDelegate:self];
    }
    
    if ([vc isKindOfClass:OPMLVC.class]) {
        
        [self presentViewController:vc animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        return;
    }
    
    // Push the view controller.
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - <SettingsChanges>

- (void)didChangeSettings
{
    if (!_settingsUpdated)
        _settingsUpdated = YES;
}

- (void)didUpdateTheme {
    
    _footerView = nil;
    self.tableView.tableFooterView = self.footerView;
    
    _hasAnimatedFooterView = NO;
}

#pragma mark - Getters

- (UIView *)footerView
{
    
    if(!_footerView)
    {
        _footerView = [[UIView alloc] init];
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        _footerView.backgroundColor = theme.tableColor;
        
        _footerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 112.f + 16.f);
        
        DZView *dz = [[DZView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 120.f)/2.f, 0, 120, 70.f) tintColor:theme.tintColor];
        dz.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        dz.tag = 30000;
        dz.tintColor = theme.tintColor;
        dz.backgroundColor = theme.tableColor;
        dz.contentMode = UIViewContentModeRedraw;
        
        [_footerView addSubview:dz];
        
        UILabel *_byLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70.f - 16.f, CGRectGetWidth(self.view.bounds), 30.f)];
        _byLabel.textColor = theme.subtitleColor;
        _byLabel.textAlignment = NSTextAlignmentCenter;
        _byLabel.text = @"A Dezine Zync Studios app.";
        _byLabel.font = [UIFont systemFontOfSize:12.f];
        _byLabel.transform = CGAffineTransformMakeTranslation(0, 30.f);
        _byLabel.autoresizingMask = dz.autoresizingMask;
        _byLabel.backgroundColor = theme.tableColor;
        
        [_footerView addSubview:_byLabel];
    }
    
    return _footerView;
    
}

@end
