//
//  CustomFeed.h
//  Elytra
//
//  Created by Nikhil Nigade on 25/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "Feed.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FeedVCType) {
    FeedVCTypeNatural,
    FeedVCTypeUnread,
    FeedVCTypeBookmarks,
    FeedVCTypeToday,
    FeedVCTypeFolder,
    FeedVCTypeAuthor
};

//@interface CustomFeed : Feed
//
//@property (nonatomic, copy) NSString * imageName;
//@property (nonatomic, strong) UIColor * tintColor;
//@property (nonatomic, assign) FeedVCType feedType;
//
//- (instancetype)initWithTitle:(NSString * _Nonnull)title imageName:(NSString * _Nonnull)imageName tintColor:(UIColor * _Nonnull)tintColor feedType:(FeedVCType)feedType;
//
//@end

NS_ASSUME_NONNULL_END
