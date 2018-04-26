//
//  NewFolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFeedVC.h"

#import "Folder.h"

@interface NewFolderVC : NewFeedVC

+ (UINavigationController *)instanceWithFolder:(Folder *)folder;

@property (nonatomic, weak, readonly) Folder *folder;

@end
