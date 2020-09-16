//
//  SyncChange.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SyncChange : NSObject

@property (nonatomic, copy) NSNumber *feedID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSNumber *order;

@end

NS_ASSUME_NONNULL_END
