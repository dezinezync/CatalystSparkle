//
//  FeedsSearchResults.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsSearchResults.h"
#import "FeedsCell.h"
#import "FolderCell.h"
#import "FeedVC.h"

@interface FeedsSearchResults ()

@end

@implementation FeedsSearchResults

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FolderCell.class) bundle:nil] forCellReuseIdentifier:kFolderCell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    id obj = [self.DS objectAtIndexPath:indexPath];
    
    if ([obj isKindOfClass:Folder.class]) {
        cell = [tableView dequeueReusableCellWithIdentifier:kFolderCell forIndexPath:indexPath];
        [(FolderCell *)cell configureFolder:(Folder *)obj];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
        [(FeedsCell *)cell configure:(Feed *)obj];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
    
    UIViewController *presenting = self.presentingViewController;
    
    UINavigationController *nav = [presenting navigationController];
    
    [nav pushViewController:vc animated:YES];
}

@end
