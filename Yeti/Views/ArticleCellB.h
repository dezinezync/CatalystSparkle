//
//  ArticleCellB.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kiPadArticleCell;

@interface ArticleCellB : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

- (void)configure:(FeedItem * _Nonnull)item customFeed:(BOOL)isCustomFeed sizeCache:(NSMutableDictionary *)sizeCache;

@property (weak, nonatomic) NSMutableDictionary *sizeCache;
@property (weak, nonatomic) FeedItem *item;

@end

NS_ASSUME_NONNULL_END
