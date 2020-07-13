//
//  FeedVC+ContextMenus.h
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+SearchController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeedVC (ContextMenus) <UIAdaptivePresentationControllerDelegate>

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point;

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller;

- (void)showAuthorVC:(NSString *)author;

@end

NS_ASSUME_NONNULL_END
