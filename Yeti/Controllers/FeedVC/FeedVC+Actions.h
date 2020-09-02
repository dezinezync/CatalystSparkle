//
//  FeedVC+Actions.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeedVC (Actions)

- (void)loadArticle;

- (void)_markVisibleRowsRead;

- (void)didTapAllRead:(id)sender;

- (void)didLongPressOnAllRead:(id)sender;

- (void)_didFinishAllReadActionSuccessfully;

- (void)didTapNotifications:(UIBarButtonItem *)sender;

- (void)subscribeToFeed:(UIBarButtonItem *)sender;

- (void)subscribedToFeed:(NSNotification *)note;

- (void)didTapSidebarButton:(UIBarButtonItem *)sender;

- (void)didTapSortOptions:(UIBarButtonItem *)sender;

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender;

- (void)markAllNewerRead:(NSIndexPath *)indexPath;

- (void)markAllOlderRead:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
