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
    
    [presenting to_showDetailViewController:vc sender:self];
}

@end
