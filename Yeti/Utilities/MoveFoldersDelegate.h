//
//  MoveFoldersDelegate.h
//  Elytra
//
//  Created by Nikhil Nigade on 19/02/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MoveFoldersDelegate <NSObject>

/// This delegate method is called when the user successfully moves the Feed from one folder to another. Either of the folder params can be nil if the Feed is moved out from a folder or moved in to a new folder.
/// @param feed The feed which moved.
/// @param sourceFolder The source folder.
/// @param destinationFolder The destination folder.
- (void)feed:(Feed * _Nonnull)feed didMoveFromFolder:(Folder * _Nullable)sourceFolder toFolder:(Folder * _Nullable)destinationFolder;

@end

NS_ASSUME_NONNULL_END
