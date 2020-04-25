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
#import "DetailFeedVC.h"
#import "SplitVC.h"

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
    
    DetailFeedVC *vc = [[DetailFeedVC alloc] initWithFeed:feed];
    
    UIViewController *presenting = self.presentingViewController;
    
    BOOL isPhone = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
                   && self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    CGFloat maxSize = MAX([presenting to_splitViewController].view.bounds.size.width, [presenting to_splitViewController].view.bounds.size.height);
    
    if (isPhone || (isPhone == NO && maxSize <= 1024.f)) {
         [presenting to_showSecondaryViewController:vc sender:self];
     }
     else {
         UIViewController *detailVC = presenting.to_splitViewController.detailViewController ?: [(SplitVC *)[presenting to_splitViewController] emptyVC];
       
         UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
       
         [presenting to_showSecondaryViewController:nav setDetailViewController:detailVC sender:self];
     }
}

@end
