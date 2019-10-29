//
//  MoveFoldersVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FeedsManager.h"

@interface MoveFoldersVC : UITableViewController

+ (UINavigationController *)instanceForFeed:(Feed *)feed;

@property (nonatomic, weak, readonly) Feed *feed;

@end
