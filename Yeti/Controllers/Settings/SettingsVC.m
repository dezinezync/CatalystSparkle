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
#import "OPMLDeckController.h"
#import "MiscVC.h"
#import "PushVC.h"

#import <DZKit/DZView.h>
#import "DZWebViewController.h"
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/DZMessagingController.h>

#import "YetiThemeKit.h"
#import "DBManager+CloudCore.h"

#import <sys/utsname.h>

NSString* deviceName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.tableView.backgroundColor = theme.tableColor;
    self.view.backgroundColor = theme.tableColor;
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    if (@available(iOS 13, *)) {}
    else {
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"arrow_down"] style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone)];
        done.accessibilityLabel = @"Close";
        done.accessibilityHint = @"Close settings";
        
        self.navigationItem.rightBarButtonItem = done;
    }
    
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    [self didUpdateTheme];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
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

#pragma mark -

#pragma mark - Actions

- (void)didTapDone {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didChangeBackgroundRefreshPreference:(UISwitch *)sw {
    
    [SharedPrefs setValue:@(sw.isOn) forKey:propSel(backgroundRefresh)];
    
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
        {
            if (@available(iOS 13, *)) {
                return 3;
            }
            else {
                return 2;
            }
        }
            break;
        case 1:
            return 6;
            break;
        case 2:
            return 4;
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
    
    if (@available(iOS 13, *)) {
        cell.backgroundColor = theme.backgroundColor;
    }
    else {
        cell.backgroundColor = theme.cellColor;
    }
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    if (cell.accessoryView != nil) {
        cell.accessoryView = nil;
    }
    
    cell.detailTextLabel.text = nil;
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
        {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Your Account";
                    break;
                case 1:
                    cell.textLabel.text = @"Filters";
                    break;
                default:
                    cell.textLabel.text = @"Push Notifications";
                    break;
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        case 1 :
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Appearance";
                    
                    NSString *themeName = SharedPrefs.theme;
                    
                    cell.detailTextLabel.text = [themeName isEqualToString:@"light"] ? @"Default" : [themeName capitalizedString];
                }
                    break;
                case 1:
                {
                    cell.textLabel.text = @"Background Fetch";
                    
                    UISwitch *sw = [[UISwitch alloc] init];
                    [sw setOn:SharedPrefs.backgroundRefresh];
                    [sw addTarget:self action:@selector(didChangeBackgroundRefreshPreference:) forControlEvents:UIControlEventValueChanged];
                    
                    [sw setOnTintColor:self.view.tintColor];
                    
                    cell.accessoryView = sw;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                    break;
                case 2: {
                    cell.textLabel.text = @"Image Loading";
                    cell.detailTextLabel.text = SharedPrefs.imageLoading;
                }
                    break;
                case 3:
                    cell.textLabel.text = @"External Apps";
                    break;
                case 4:
                    cell.textLabel.text = @"Import/Export OPML";
                    break;
                case 5:
                    cell.textLabel.text = @"Miscellaneous";
                    break;
                    break;
                default:
                    break;
            }
            
            if (indexPath.row != 1) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
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
                case 1:
                {
                    cell.textLabel.text = @"Rate";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                    break;
                case 2:
                {
                    cell.textLabel.text = @"Attributions";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                    break;
                default:
                {
                    cell.textLabel.text = @"Contact";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                    
            }
            
            
            if (indexPath.row != 0) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
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
    
    UITableViewStyle style = UITableViewStyleGrouped;
    
    if (@available(iOS 13, *)) {
        style = UITableViewStyleInsetGrouped;
    }
    
    UIViewController *vc;
    // vc = [[<#DetailViewController#> alloc] initWithNibName:NSStringFromClass(<#NSString * _Nonnull aClassName#>) bundle:nil];
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    vc = [[AccountVC alloc] initWithStyle:style];
                    break;
                case 1:
                    vc = [[FiltersVC alloc] initWithStyle:style];
                    break;
                default:
                    vc = [[PushVC alloc] initWithStyle:UITableViewStylePlain];
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0:
                {
                    vc = [[ThemeVC alloc] initWithStyle:style];
                }
                    break;
                case 2:
                {
                    vc = [[ImageLoadingVC alloc] initWithStyle:style];
                }
                    break;
                case 3:
                    vc = [[ExternalAppsVC alloc] initWithStyle:style];
                    break;
                case 4:
                {
                    if (@available(iOS 13, *)) {
                        OPMLVC *vc1 = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
                        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc1];
                        nav.modalTransitionStyle = UIModalPresentationAutomatic;
                        
                        vc = nav;
                    }
                    else {
                        vc = [[OPMLDeckController alloc] init];
                    }
                }
                    break;
                case 5:
                    vc = [[MiscVC alloc] initWithStyle:style];
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
                
                if (@available(iOS 13, *)) {
                    NSString *tint = [UIColor hexFromUIColor:theme.tintColor];
                    NSString *js = formattedString(@"anchorStyle(\"%@\")", tint);
                    
                    webVC.evalJSOnLoad = js;
                }
                else {
                    if (![theme.name isEqualToString:@"light"]) {
                        NSString *tint = [UIColor hexFromUIColor:theme.tintColor];
                        NSString *js = formattedString(@"darkStyle(%@,\"%@\")", [YTThemeKit.theme.name isEqualToString:@"black"] ? @0 : @1, tint);
                        
                        webVC.evalJSOnLoad = js;
                    }
                }
                
                vc = webVC;
            }
            else if (indexPath.row == 1) {
                NSURL *URL = formattedURL(@"https://itunes.apple.com/app/id1433266971?action=write-review");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
                });
            }
            else if (indexPath.row == 3) {
                [self showContactInterface];
            }
            break;
    }
    
    if ([vc conformsToProtocol:@protocol(SettingsNotifier)]) {
        [(id<SettingsNotifier>)vc setSettingsDelegate:self];
    }
    
    if ([vc isKindOfClass:OPMLDeckController.class] || [vc isKindOfClass:UINavigationController.class]) {
        
        [self presentViewController:vc animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        return;
    }
    
    // Push the view controller.
    if (vc) {
        [self showViewController:vc sender:self];
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.tableView.backgroundColor = theme.tableColor;
    self.view.backgroundColor = theme.tableColor;
    
    self.tableView.tableFooterView = self.footerView;
    
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    
    [self.tableView reloadData];
    
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [self.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
    });
    
    _hasAnimatedFooterView = NO;
}

#pragma mark -

- (void)showContactInterface {
    
    DZMessagingAttachment *attachment = [[DZMessagingAttachment alloc] init];
    attachment.fileName = @"debugInfo.txt";
    attachment.mimeType = @"text/plain";
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *model = deviceName();
    NSString *iOSVersion = formattedString(@"%@ %@", device.systemName, device.systemVersion);
    NSString *deviceUUID = device.identifierForVendor.UUIDString;
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    
    NSString *formatted = formattedString(@"Model: %@ %@\nDevice UUID: %@\nAccount ID: %@\nApp: %@ (%@)", model, iOSVersion, deviceUUID, MyFeedsManager.userIDManager.UUIDString, appVersion, buildNumber);
    
    attachment.data = [formatted dataUsingEncoding:NSUTF8StringEncoding];
    
    [DZMessagingController presentEmailWithBody:@""
                                        subject:@"Elytra Support"
                                     recipients:@[@"support@elytra.app"]
                                    attachments:@[attachment]
                                 fromController:self];
    
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
        _byLabel.numberOfLines = 0;
        _byLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _byLabel.transform = CGAffineTransformMakeTranslation(0, 30.f);
        _byLabel.autoresizingMask = dz.autoresizingMask;
        _byLabel.backgroundColor = theme.tableColor;
        
        [MyDBManager.uiConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            
            NSString *token = [transaction objectForKey:syncToken inCollection:SYNC_COLLECTION];
            
            if (token != nil) {
                NSString *dateString = [token decodeBase64];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
                
                NSDate *date = [formatter dateFromString:dateString];
                
                formatter.dateStyle = NSDateFormatterShortStyle;
                formatter.timeStyle = NSDateFormatterShortStyle;
                formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                
                NSString *formatted = [formatter stringFromDate:date];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _byLabel.text = formattedString(@"A Dezine Zync App.\nLast Synced: %@", formatted);
                    [_byLabel sizeToFit];
                    [_byLabel setNeedsLayout];
                    [_byLabel layoutIfNeeded];
                    
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    _byLabel.text = @"A Dezine Zync App.";
                    [_byLabel sizeToFit];
                    [_byLabel setNeedsLayout];
                    [_byLabel layoutIfNeeded];
                    
                });
                
            }
            
        }];
        
        [_footerView addSubview:_byLabel];
    }
    
    return _footerView;
    
}

@end
