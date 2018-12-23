//
//  ChangeSet.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncChange.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChangeSet : NSObject

@property (nonatomic, copy) NSString *changeToken;
@property (nonatomic, strong) NSArray <SyncChange *> *changes;

@end

NS_ASSUME_NONNULL_END
