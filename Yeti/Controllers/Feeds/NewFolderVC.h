//
//  NewFolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFeedVC.h"

#import "Folder.h"
#import "SidebarVC.h"

@interface NewFolderVC : NewFeedVC

+ (UINavigationController * _Nonnull)instanceWithFolder:(Folder * _Nonnull)folder feedsVC:(FeedsVC * _Nonnull)feedsVC indexPath:(NSIndexPath * _Nonnull)indexPath;

@property (nonatomic, weak, readonly) Folder * _Nullable folder;

// used when editing a folder
@property (nonatomic, weak) FeedsVC * _Nullable feedsVC;
@property (nonatomic, weak) NSIndexPath * _Nullable folderIndexPath;

@end
