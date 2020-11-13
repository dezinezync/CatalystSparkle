//
//  AddFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DZKit/NSString+Extras.h>

#import "UIViewController+ScrollLoad.h"
#import "UIViewController+Stateful.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddFeedVC : UICollectionViewController <ControllerState> {
@public
    BOOL _hasProcessedPasteboard;
}

+ (UINavigationController *)instanceInNavController;

@property (atomic, assign) NSInteger page;

@property (nonatomic, weak) UISearchBar *searchBar;

@property (nonatomic, copy) NSString *errorTitle;
@property (nonatomic, copy) NSString *errorBody;

@property (weak) NSURLSessionTask *networkTask;

@property (atomic, assign) StateType controllerState;

@property (atomic, assign) BOOL isFromAddFeed;

@property (nonatomic, strong) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@end

NS_ASSUME_NONNULL_END
