//
//  MoveFoldersVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 26/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FeedsManager.h"

@protocol MoveFoldersDelegate <NSObject>

/// This delegate method is called when the user successfully moves the Feed from one folder to another. Either of the folder params can be nil if the Feed is moved out from a folder or moved in to a new folder.
/// @param feed The feed which moved.
/// @param sourceFolder The source folder.
/// @param destinationFolder The destination folder.
- (void)feed:(Feed * _Nonnull)feed didMoveFromFolder:(Folder * _Nullable)sourceFolder toFolder:(Folder * _Nullable)destinationFolder;

@end

@interface MoveFoldersVC : UITableViewController

+ (UINavigationController * _Nonnull)instanceForFeed:(Feed * _Nonnull)feed delegate:(id<MoveFoldersDelegate> _Nullable)delegate;

@property (nonatomic, weak, readonly, nullable) Feed *feed;

@property (nonatomic, weak, nullable) id<MoveFoldersDelegate> delegate;

@end
