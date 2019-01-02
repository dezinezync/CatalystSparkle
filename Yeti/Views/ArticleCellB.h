//
//  ArticleCellB.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"
#import "YetiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ArticleCellDelegate <NSObject>

@optional
- (void)didTapTag:(NSString *)tag;

@end

extern NSString *const kiPadArticleCell;

@interface ArticleCellB : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@property (weak, nonatomic) IBOutlet UIImageView *markerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleWidthConstraint;

- (void)configure:(FeedItem * _Nonnull)item customFeed:(FeedType)isCustomFeed sizeCache:(NSMutableArray *)sizeCache;

//@property (weak, nonatomic) NSMutableDictionary *sizeCache;
@property (weak, nonatomic) FeedItem *item;

@property (weak, nonatomic) id<ArticleCellDelegate> delegate;

- (void)showSeparator:(BOOL)showSeparator;

- (void)setupAppearance;

@end

NS_ASSUME_NONNULL_END
