//
//  DetailFeedVC+Actions.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailFeedVC (Actions)

- (void)loadArticle;

- (void)_markVisibleRowsRead;

- (void)didTapAllRead:(id)sender;

- (void)didLongPressOnAllRead:(id)sender;

- (void)_didFinishAllReadActionSuccessfully;

- (void)didTapNotifications:(UIBarButtonItem *)sender;

- (void)subscribeToFeed:(UIBarButtonItem *)sender;

- (void)subscribedToFeed:(NSNotification *)note;

@end

NS_ASSUME_NONNULL_END
