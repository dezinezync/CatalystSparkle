//
//  FeedSearchResults.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedSearchResults.h"

#import "ArticleCell.h"
#import "ArticleVC.h"

#import <DZKit/EFNavController.h>

@interface FeedSearchResults ()

@end

@implementation FeedSearchResults

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCell.class) bundle:nil] forCellReuseIdentifier:kArticleCell];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:kArticleCell forIndexPath:indexPath];
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    [cell configure:item];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    
    UIViewController *presenting = self.presentingViewController;
    
    UINavigationController *nav = [presenting navigationController];
    
    if (presenting.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        EFNavController *navVC = [[EFNavController alloc] initWithRootViewController:vc];
        
        [presenting.splitViewController showDetailViewController:navVC sender:self];

    }
    else {
        [nav pushViewController:vc animated:YES];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        item.read = YES;
        [[(UITableViewController *)presenting tableView] reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [[(UITableViewController *)presenting tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    });

}

@end
