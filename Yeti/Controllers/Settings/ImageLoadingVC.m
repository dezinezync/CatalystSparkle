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
NSString *const kXImageLoadingCell = @"cell.imageLoading";

@interface ImageLoadingVC ()

@property (nonatomic, assign) NSInteger selected, bandwidth;

@property (nonatomic, strong) UILabel *footerSizingLabel;

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
    
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kXImageLoadingCell];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kXSwitchCell];
    
    self.tableView.estimatedRowHeight = 44.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.tableView.estimatedSectionFooterHeight = 80.f;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.tableView.backgroundColor = theme.tableColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UILabel *)footerSizingLabel {
    
    if (!_footerSizingLabel) {
        UILabel *label = [UILabel new];
        label.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 0.f);
        label.font = TypeFactory.shared.footnoteFont;
        label.numberOfLines = 0;
        
        _footerSizingLabel = label;
        
    }
    
    return _footerSizingLabel;
    
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
        return @"Elytra can optionally use the weserv.nl Image Proxy for loading images optimized to be displayed on this device. Images loaded via the Image Proxy are smaller in size and therefore load faster and save bandwidth.";
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//
//    self.footerSizingLabel.frame = CGRectMake(0, 0, tableView.safeAreaLayoutGuide.layoutFrame.size.width, 0.f);
//    self.footerSizingLabel.text = [self tableView:tableView titleForFooterInSection:section];
//    [self.footerSizingLabel sizeToFit];
//
//    CGFloat height = self.footerSizingLabel.frame.size.height + 12.f;
//
//    return height;
//
//}

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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kXImageLoadingCell forIndexPath:indexPath];
    
    cell.separatorInset = UIEdgeInsetsZero;
    
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
            [aSwitch setOnTintColor:self.view.tintColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.accessoryView = aSwitch;
        }
            break;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    if (@available(iOS 13, *)) {
        cell.backgroundColor = theme.backgroundColor;
    }
    else {
        cell.backgroundColor = theme.cellColor;
    }
    
    if (indexPath.section != 2 && indexPath.section != 3) {
        UIView *selected = [UIView new];
        selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
        cell.selectedBackgroundView = selected;
    }
    
    return cell;
}

#pragma mark - Actions

- (void)didChangeCoverImagesPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(articleCoverImages)];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        
        [self.settingsDelegate didChangeSettings];
        
    }
    
}

- (void)didChangeImageProxyPreference:(UISwitch *)sender {
    
    [SharedPrefs setValue:@(sender.isOn) forKey:propSel(imageProxy)];
    
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


@end
