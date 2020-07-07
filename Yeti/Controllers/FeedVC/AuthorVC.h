//
//  AuthorVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface AuthorVC : FeedVC

@property (nonatomic, copy) NSString *author;

- (instancetype)initWithFeed:(Feed *)feed author:(NSString *)author;

@end

NS_ASSUME_NONNULL_END
