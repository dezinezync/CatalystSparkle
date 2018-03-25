//
//  FeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

#import "UITableViewController+ScrollLoad.h"

@interface FeedVC : UITableViewController <ScrollLoading> {
    NSOperation *_searchOperation;
}

@property (nonatomic, getter=isLoadingNext) BOOL loadingNext;

- (instancetype _Nonnull)initWithFeed:(Feed * _Nonnull)feed;

@property (nonatomic, strong) Feed * _Nullable feed;

@property (nonatomic, strong) NSOperation * _Nullable searchOperation;

@end
