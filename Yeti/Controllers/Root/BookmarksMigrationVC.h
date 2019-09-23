//
//  BookmarksMigrationVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookmarksManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookmarksMigrationVC : UIViewController

@property (nonatomic, strong) BookmarksManager *bookmarksManager;

@property (nonatomic, copy, nullable) void (^completionBlock)(BOOL success);

@end

NS_ASSUME_NONNULL_END
