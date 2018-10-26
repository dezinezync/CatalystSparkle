//
//  DetailFeedHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kDetailFeedHeaderView;

@interface DetailFeedHeaderView : UICollectionReusableView

@property (nonatomic, weak) FeedHeaderView *headerContent;

- (void)setupAppearance;

@end

NS_ASSUME_NONNULL_END
