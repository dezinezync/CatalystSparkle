//
//  MoveFoldersVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Elytra-Swift.h"

@interface MoveFoldersVC : UITableViewController

+ (UINavigationController * _Nonnull)instanceForFeed:(Feed * _Nonnull)feed delegate:(id<MoveFoldersDelegate> _Nullable)delegate;

@property (nonatomic, weak, readonly, nullable) Feed *feed;

@property (nonatomic, weak, nullable) id<MoveFoldersDelegate> delegate;

@end
