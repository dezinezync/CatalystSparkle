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

#import "Elytra-Swift.h"

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

#import "PrefsManager.h"

#if TARGET_OS_MACCATALYST
typedef NS_ENUM(NSUInteger, SectionOneRows) {
    SectionBackgroundFetch = 0,
    SectionImageLoading = 1,
    SectionOPML = 2,
    SectionMisc = 3
};
#else
typedef NS_ENUM(NSUInteger, SectionOneRows) {
    SectionAppearance = 0,
    SectionBackgroundFetch = 1,
    SectionImageLoading = 2,
    SectionExternalApps = 3,
    SectionOPML = 4,
    SectionMisc = 5
};
#endif

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
    
#if TARGET_OS_MACCATALYST
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    
#else
    self.tableView.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return UIColor.secondarySystemGroupedBackgroundColor;
        }
        else {
            return UIColor.systemGroupedBackgroundColor;
        }
        
    }];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
#endif
    
    [self.tableView registerClass:SettingsCell.class forCellReuseIdentifier:kSettingsCell];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"] style:UIBarButtonItemStyleDone target:self action:@selector(didTapDone)];

    self.tableView.tableFooterView = self.footerView;
    
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
#if TARGET_OS_MACCATALYST
            return 3;
#else
            return 4;
#endif
            break;
        case 1:
#if TARGET_OS_MACCATALYST
            return 4;
#else
            return 6;
#endif
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
    
    cell.textLabel.textColor = UIColor.labelColor;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    
    cell.backgroundColor = UIColor.systemBackgroundColor;
    
#if !TARGET_OS_MACCATALYST
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
#endif
    
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
                case 2:
                    cell.textLabel.text = @"Push Notifications";
                    break;
                case 3:
                    cell.textLabel.text = @"Force Re-Sync Data";
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
        case 1 :
            switch (indexPath.row) {
#if TARGET_OS_MACCATALYST
                case 0:
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
                case 1:
                {
                    cell.textLabel.text = @"Image Loading";
                    cell.detailTextLabel.text = SharedPrefs.imageLoading;
                }
                    break;
                case 2:
                    cell.textLabel.text = @"Import/Export Subscriptions";
                    break;
                case 3:
                    cell.textLabel.text = @"Miscellaneous";
                    break;
                    break;
                default:
                    break;
            }
            
            if (indexPath.row != 0) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
#else
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
#endif
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
    
    if (indexPath.row == 3 && indexPath.section == 0) {
        
        image = [UIImage systemImageNamed:@"arrow.clockwise.circle.fill"];
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    }
    
    cell.imageView.image = image;
    
    return cell;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    
    if (indexPath.section == 0 && indexPath.row == 3) {
        
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        [self.coordinator prepareForFullResync];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        
        return;
        
    }
    
    UITableViewStyle style = UITableViewStyleInsetGrouped;
    
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
                {
                    UITableViewStyle style = UITableViewStylePlain;
                    
#if TARGET_OS_MACCATALYST
                    style = UITableViewStyleInsetGrouped;
#endif
                    
                    vc = [[PushVC alloc] initWithStyle:style];
                }
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
#if TARGET_OS_MACCATALYST
                case 1:
                {
                    vc = [[ImageLoadingVC alloc] initWithStyle:style];
                }
                    break;
                case 2:
                {
                    OPMLVC *vc1 = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc1];
                    nav.modalTransitionStyle = UIModalPresentationAutomatic;
                    
                    vc = nav;
                }
                    break;
                case 3:
                    vc = [[MiscVC alloc] initWithStyle:style];
                    break;
                default:
                    break;
#else
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
                    OPMLVC *vc1 = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
                    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc1];
                    nav.modalPresentationStyle = UIModalPresentationAutomatic;
                    
                    vc = nav;
                }
                    break;
                case 5:
                    vc = [[MiscVC alloc] initWithStyle:style];
                    break;
                default:
                    break;
#endif
            }
            break;
        default:
            if (indexPath.row == 2) {
                DZWebViewController *webVC = [[DZWebViewController alloc] init];
                webVC.title = @"Attributions";
                
                webVC.URL = [[NSBundle bundleForClass:self.class] URLForResource:@"attributions" withExtension:@"html"];
                
                NSString *tint = [UIColor hexFromUIColor:SharedPrefs.tintColor];
                NSString *js = formattedString(@"anchorStyle(\"%@\")", tint);
                
                webVC.evalJSOnLoad = js;
                
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
    
    vc.coordinator = self.coordinator;
    
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
        
#if TARGET_OS_MACCATALYST
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnSecondary];
#else
        [self showViewController:vc sender:self];
#endif
        
    }
    else {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
 
    if (indexPath.section == 0 && indexPath.row == 3) {
        
        weakify(self);
        
        UIContextMenuConfiguration *config = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
           
            UIAction *resyncAll = [UIAction actionWithTitle:@"Resync All" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                strongify(self);
                
                [self.coordinator prepareForFullResync];
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                
            }];
            
            UIAction *resyncFeeds = [UIAction actionWithTitle:@"Resync Feeds" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                strongify(self);
                
                [self.coordinator prepareForFeedsResync];
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                
            }];
           
            return [UIMenu menuWithChildren:@[resyncAll, resyncFeeds]];
            
        }];
        
        return config;
    
    }
    
    return nil;
}
    

#pragma mark - <SettingsChanges>

- (void)didChangeSettings
{
    if (!_settingsUpdated)
        _settingsUpdated = YES;
}

#pragma mark -

- (void)showContactInterface {
    
    [self.coordinator showContactInterface];
    
}

#pragma mark - Getters

- (UIView *)footerView
{
    
    if(!_footerView)
    {
        _footerView = [[UIView alloc] init];
        
        _footerView.backgroundColor = self.tableView.backgroundColor;
        
        _footerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, 112.f + 16.f);
        
        DZView *dz = [[DZView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 120.f)/2.f, 0, 120, 70.f) tintColor:self.view.tintColor];
        dz.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        dz.tag = 30000;
        dz.tintColor = self.view.tintColor;
        dz.backgroundColor = self.tableView.backgroundColor;
        dz.contentMode = UIViewContentModeRedraw;
        
        [_footerView addSubview:dz];
        
        UILabel *_byLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70.f - 16.f, CGRectGetWidth(self.view.bounds), 30.f)];
        _byLabel.textColor = UIColor.secondaryLabelColor;
        _byLabel.textAlignment = NSTextAlignmentCenter;
        _byLabel.numberOfLines = 0;
        _byLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _byLabel.transform = CGAffineTransformMakeTranslation(0, 30.f);
        _byLabel.autoresizingMask = dz.autoresizingMask;
        _byLabel.backgroundColor = self.tableView.backgroundColor;
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _byLabel.text = formattedString(@"A Dezine Zync App.");
            [_byLabel sizeToFit];
            [_byLabel setNeedsLayout];
            [_byLabel layoutIfNeeded];
            
        });
        
        [_footerView addSubview:_byLabel];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleCWLogging)];
        tap.numberOfTapsRequired = 5;
        
        [_footerView addGestureRecognizer:tap];
        
    }
    
    return _footerView;
    
}

- (void)toggleCWLogging {
    
//    BOOL isEnabled = MyFeedsManager.debugLoggingEnabled;
//
//    UIAlertController *avc = nil;
//
//    if (isEnabled) {
//
//        avc = [UIAlertController alertControllerWithTitle:@"Stop Debug Session" message:@"Are you sure you want to stop the debug session?" preferredStyle:UIAlertControllerStyleAlert];
//
//        [avc addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
//            CWLog(@"Debug Logging Session Ended");
//
//            MyFeedsManager.debugLoggingEnabled = NO;
//
//        }]];
//
//        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
//
//    }
//    else {
//
//        avc = [UIAlertController alertControllerWithTitle:@"Start Debug Session" message:@"Are you sure you want to start the debug session?" preferredStyle:UIAlertControllerStyleAlert];
//
//        [avc addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//
//            MyFeedsManager.debugLoggingEnabled = YES;
//
//            CWLog(@"Debug Logging Session Started");
//
//        }]];
//
//        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
//
//    }
//
//    [self presentViewController:avc animated:YES completion:nil];
    
}

@end
