//
//  FeedHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

@class Feed;
@class Author;

@protocol FeedHeaderViewDelegate <NSObject>

- (void)didTapAuthor:(Author * _Nonnull)author;

@end

@interface FeedHeaderView : NibView

- (void)configure:(Feed * _Nonnull)feed;

- (void)setupAppearance;

@property (nonatomic, weak) UIImageView * _Nullable shadowImage;

@property (nonatomic, weak, nullable) id <FeedHeaderViewDelegate> delegate;

@end
