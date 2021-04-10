//
//  NewFolderController.h
//  Elytra
//
//  Created by Nikhil Nigade on 15/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Coordinator;

typedef void (^folderControllerCompletion)(id _Nullable folder, BOOL completed, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface NewFolderController : NSObject

- (instancetype)initWithFolder:(id _Nullable)exisitingFolder
                   coordinator:(Coordinator * _Nonnull)coordinator
                    completion:(folderControllerCompletion)completionBlock;

@property (nonatomic, weak) id exisitingFolder;

@property (nonatomic, weak) Coordinator *coordinator;

@property (nonatomic, copy) folderControllerCompletion completionHandler;

- (void)start;

@property (nonatomic, assign, readonly) BOOL completed;

@end

NS_ASSUME_NONNULL_END
