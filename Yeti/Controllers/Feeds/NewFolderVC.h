//
//  NewFolderVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Folder;

@interface NewFolderVC : UIViewController

+ (UINavigationController * _Nonnull)instanceWithFolder:(id _Nonnull)folder;

@property (nonatomic, weak, readonly) Folder * _Nullable folder;

@end
