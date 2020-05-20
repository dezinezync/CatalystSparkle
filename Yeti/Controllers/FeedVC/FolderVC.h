//
//  FolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface FolderVC : FeedVC

@property (nonatomic, weak) Folder *folder;

+ (UINavigationController *)instanceWithFolder:(Folder *)folder;

- (instancetype)initWithFolder:(Folder *)folder;

@end

NS_ASSUME_NONNULL_END
