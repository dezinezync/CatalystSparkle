//
//  NewFolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFeedVC.h"

#import "Folder.h"
#import "FeedsVC.h"

@interface NewFolderVC : NewFeedVC

+ (UINavigationController *)instanceWithFolder:(Folder * _Nonnull)folder feedsVC:(FeedsVC * _Nonnull)feedsVC indexPath:(NSIndexPath *)indexPath;

@property (nonatomic, weak, readonly) Folder *folder;

// used when editing a folder
@property (nonatomic, weak) FeedsVC *feedsVC;
@property (nonatomic, weak) NSIndexPath *folderIndexPath;

@end
