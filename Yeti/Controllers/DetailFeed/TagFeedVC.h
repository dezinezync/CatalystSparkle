//
//  TagFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface TagFeedVC : DetailFeedVC

@property (nonatomic, strong) NSString *tag;

- (instancetype _Nonnull)initWithTag:(NSString * _Nullable)tag;

@end

NS_ASSUME_NONNULL_END
