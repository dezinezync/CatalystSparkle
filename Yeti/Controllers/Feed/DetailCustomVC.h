//
//  DetailCustomVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailCustomVC : DetailFeedVC

@property (nonatomic, assign, getter=isUnread) BOOL unread;

@end

NS_ASSUME_NONNULL_END
