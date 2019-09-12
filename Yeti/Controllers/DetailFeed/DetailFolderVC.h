//
//  DetailFolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 15/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"
#import "Folder.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailFolderVC : DetailFeedVC

@property (nonatomic, strong) Folder *folder;

+ (UINavigationController *)instanceWithFolder:(Folder * _Nullable)folder;

- (instancetype _Nonnull)initWithFolder:(Folder * _Nullable)folder;

@end

NS_ASSUME_NONNULL_END
