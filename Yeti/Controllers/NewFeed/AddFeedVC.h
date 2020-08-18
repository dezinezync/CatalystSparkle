//
//  AddFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewFeedDeckController.h"

#import <DZKit/NSString+Extras.h>

#import "UIViewController+ScrollLoad.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddFeedVC : UITableViewController

+ (NewFeedDeckController *)instanceInNavController;

@property (atomic, assign) NSInteger page;

@property (nonatomic, weak) UISearchBar *searchBar;

@property (nonatomic, copy) NSString *errorTitle;
@property (nonatomic, copy) NSString *errorBody;

//@property (nonatomic, strong, readonly) DZBasicDatasource *DS;

@property (weak) NSURLSessionTask *networkTask;

@end

NS_ASSUME_NONNULL_END
