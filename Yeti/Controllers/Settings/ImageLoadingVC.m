//
//  ImageLoadingVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImageLoadingVC.h"
#import "LayoutConstants.h"

@interface ImageLoadingVC ()

@property (nonatomic, assign) NSInteger selected, bandwidth;

@end

@implementation ImageLoadingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Image Loading";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *val1 = [defaults stringForKey:kDefaultsImageLoading];
    NSString *val2 = [defaults stringForKey:kDefaultsImageBandwidth];
    
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Resolution";
    
    return @"Bandwidth";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0)
        return @"The above setting only works when the Article source provides these options. If no such option is provided in the article source, the original image is always loaded.";
    
    return @"The above setting is also used for galleries and Youtube video previews.";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
            
        default:
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
    }
    
    return cell;
}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    CGRect frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 24.f);
//
//    UITextView *label = [[UITextView alloc] initWithFrame:frame];
//    label.layoutMargins = self.tableView.layoutMargins;
//    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
//    label.contentInset = UIEdgeInsetsMake(0, LayoutPadding, 0, LayoutPadding);
//    label.editable = NO;
//    label.backgroundColor = UIColor.groupTableViewBackgroundColor;
//    label.opaque = YES;
//
//    if (section == 0)
//        label.text = @"The above setting only works when the Article source provides these options. If no such option is provided in the article source, the original image is always loaded.";
//    else
//        label.text = @"The above setting is also used for galleries and Youtube video previews.";
//
//    frame.size = [label sizeThatFits:CGSizeMake(frame.size.width - (LayoutPadding * 2), CGFLOAT_MAX)];
//    label.frame = frame;
//
//    [label.heightAnchor constraintGreaterThanOrEqualToConstant:frame.size.height].active = YES;
//
//    return label;
//}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        self.selected = indexPath.row;
    else
        self.bandwidth = indexPath.row;
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
    
    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (indexPath.section == 0) {
        if (self.selected == 0)
            [defaults setValue:ImageLoadingLowRes forKey:kDefaultsImageLoading];
        else if (self.selected == 1)
            [defaults setValue:ImageLoadingMediumRes forKey:kDefaultsImageLoading];
        else
            [defaults setValue:ImageLoadingHighRes forKey:kDefaultsImageLoading];
    }
    else {
        if (self.bandwidth == 0)
            [defaults setValue:ImageLoadingNever forKey:kDefaultsImageBandwidth];
        else if (self.bandwidth == 1)
            [defaults setValue:ImageLoadingOnlyWireless forKey:kDefaultsImageBandwidth];
        else
            [defaults setValue:ImageLoadingAlways forKey:kDefaultsImageBandwidth];
    }
    
    [defaults synchronize];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        
        [self.settingsDelegate didChangeSettings];
        
    }
}

@end
