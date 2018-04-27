//
//  FeedsSearchResults.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsSearchResults.h"
#import "FeedsCell.h"
#import "FeedVC.h"

@interface FeedsSearchResults ()

@end

@implementation FeedsSearchResults

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
    
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Folder.class]) {
        [cell configureFolder:(Folder *)feed];
    }
    else {
        [cell configure:feed];
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
