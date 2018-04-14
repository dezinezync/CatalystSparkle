//
//  FeedHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

@class Feed;

@interface FeedHeaderView : NibView

- (void)configure:(Feed *)feed;

@property (nonatomic, weak) UIImageView *shadowImage;

@end
