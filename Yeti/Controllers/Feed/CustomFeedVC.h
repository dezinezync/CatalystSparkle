//
//  CustomFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 05/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"

@interface CustomFeedVC : FeedVC <UIViewControllerRestoration>

@property (nonatomic, assign, getter=isUnread) BOOL unread;

@end
