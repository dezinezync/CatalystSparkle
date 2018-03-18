//
//  ImageLoadingVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ImageLoadingVC.h"

@interface ImageLoadingVC ()

@property (nonatomic, assign) NSInteger selected;

@end

@implementation ImageLoadingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Image Loading";
    
    NSString *val = [NSUserDefaults.standardUserDefaults stringForKey:kDefaultsImageLoading];
    
    if ([val isEqualToString:ImageLoadingMediumRes])
        self.selected = 1;
    else if ([val isEqualToString:ImageLoadingHighRes])
        self.selected = 2;
    
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageLoadingCell" forIndexPath:indexPath];
    
    // Configure the cell...
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
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selected = indexPath.row;
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
    
    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (self.selected == 0)
        [defaults setValue:ImageLoadingLowRes forKey:kDefaultsImageLoading];
    else if (self.selected == 1)
        [defaults setValue:ImageLoadingMediumRes forKey:kDefaultsImageLoading];
    else
        [defaults setValue:ImageLoadingHighRes forKey:kDefaultsImageLoading];
    
    [defaults synchronize];
    
    if (self.settingsDelegate && [self.settingsDelegate respondsToSelector:@selector(didChangeSettings)]) {
        
        [self.settingsDelegate didChangeSettings];
        
    }
}

@end
