//
//  FolderDrop.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/07/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feed.h"
#import "Folder.h"

@protocol FolderDrop <NSObject>

- (void)moveFeed:(NSString *)feed toFolder:(Folder *)folder;

@end
