//
//  ImageLoadingVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImageLoadingVC.h"
#import "LayoutConstants.h"
#import "YetiConstants.h"
#import "YetiThemeKit.h"

#import <DZNetworking/ImageLoader.h>

NSString *const kXSwitchCell = @"cell.switch";

@interface ImageLoadingVC ()

@property (nonatomic, assign) NSInteger selected, bandwidth;

@end

@implementation ImageLoadingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Image Loading";
    
    NSString *val1 = SharedPrefs.imageLoading;
    NSString *val2 = SharedPrefs.imageBandwidth;
    
    if ([val1 isEqualToString:ImageLoadingMediumRes])
        self.selected = 1;
    else if ([val1 isEqualToString:ImageLoadingHighRes])
        self.selected = 2;
    
    if ([val2 isEqualToString:ImageLoadingOnlyWireless])
        self.bandwidth = 1;
    else if ([val2 isEqualToString:ImageLoadingAlways])
        self.bandwidth = 2;
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"imageLoadingCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kXSwitchCell];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Resolution";
    else if (section == 1)
        return @"Bandwidth";
    else if (section == 2) {
        return @"Cover Images";
    }
    else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return @"The above setting only works when the Article source provides these options. If no such option is provided in the article source, the original image is always loaded.";
    else if (section == 1)
        return @"The above setting is also used for galleries and Youtube video previews.";
    else if (section == 2) {
        return @"Enabling this shows cover images in the feeds list. This setting is also affected by your setting for Bandwidth.";
    }
    else {
        return @"Elytra can optionally use the weserv.nl Image Proxy for loading images optimized to be displayed on this device.";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        return 1;
    }
    else if (section == 3) {
        return 1;
    }
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageLoadingCell" forIndexPath:indexPath];
    
    // Configure the cell...
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = ImageLoadingLowRes;
                    break;
                case 1:
                    cell.textLabel.text = ImageLoadingMediumRes;
                    break;
                default:
                    cell.textLabel.text = ImageLoadingHighRes;
                    break;
            }
            
            cell.accessoryType = self.selected == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
            
        case 1:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = ImageLoadingNever;
                    break;
                case 1:
                    cell.textLabel.text = ImageLoadingOnlyWireless;
                    break;
                default:
                    cell.textLabel.text = ImageLoadingAlways;
                    break;
            }
            
            cell.accessoryType = self.bandwidth == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case 3:
        default:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kXSwitchCell forIndexPath:indexPath];
            
            UISwitch *aSwitch = [[UISwitch alloc] init];
            BOOL pref;
            
            switch (indexPath.section) {
                case 2:
                {
                    pref = SharedPrefs.articleCoverImages;
                    [aSwitch addTarget:self action:@selector(didChangeCoverImagesPreference:) forControlEvents:UIControlEventValueChanged];
                    
                    cell.textLabel.text = @"Show cover images";
                }
                    break;
                    
                default:
                {
                    pref = SharedPrefs.imageProxy;
                    [aSwitch addTarget:self action:@selector(didChangeImageProxyPreference:) forControlEvents:UIControlEventValueChanged];
                    
                    cell.textLabel.text = @"Image Proxy";
                }
                    break;
            }
            
            [aSwitch setOn:pref];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.accessoryView = aSwitch;
        }
            break;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    cell.backgroundColor = theme.cellColor;
    
    if (indexPath.section != 2 && indexPath.section != 3) {
        UIView *selected = [UIView new];
        selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
        cell.selectedBackgroundView = selected;
    }
    
    return cell;
}

#pragma mark - Actions

- (void)didChangeCoverImagesPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:kShowArticleCoverImages];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        
        [self.settingsDelegate didChangeSettings];
        
    }
    
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        self.selected = indexPath.row;
    else
        self.bandwidth = indexPath.row;
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
    
    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
    
    if (indexPath.section == 0) {
        if (self.selected == 0)
            [SharedPrefs setValue:ImageLoadingLowRes forKey:propSel(imageLoading)];
        else if (self.selected == 1)
            [SharedPrefs setValue:ImageLoadingMediumRes forKey:propSel(imageBandwidth)];
        else
            [SharedPrefs setValue:ImageLoadingHighRes forKey:propSel(imageLoading)];
        
        [[SharedImageLoader cache] removeAllObjects];
        [[SharedImageLoader cache] removeAllObjectsFromDisk];
    }
    else {
        if (self.bandwidth == 0)
            [SharedPrefs setValue:ImageLoadingNever forKey:propSel(imageBandwidth)];
        else if (self.bandwidth == 1)
            [SharedPrefs setValue:ImageLoadingOnlyWireless forKey:propSel(imageBandwidth)];
        else
            [SharedPrefs setValue:ImageLoadingAlways forKey:propSel(imageBandwidth)];
    }
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        
        [self.settingsDelegate didChangeSettings];
        
    }
}

- (void)didChangeImageProxyPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(imageProxy)];
    
}

@end
