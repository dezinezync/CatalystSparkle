//
//  ImportVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 06/08/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Elytra-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImportVC : UITableViewController

@property (nonatomic, strong) NSArray *unmappedFeeds;
@property (nonatomic, strong) NSArray <NSString *> *unmappedFolders;

@property (nonatomic, strong) NSArray <Feed *> *feeds;
@property (nonatomic, strong) NSArray <Folder *> *folders;

@property (nonatomic, strong) NSArray <Folder *> *existingFolders;

@end

NS_ASSUME_NONNULL_END
