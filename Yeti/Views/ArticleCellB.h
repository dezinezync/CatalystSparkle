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

@interface ArticleCellB : UICollectionViewCell {
@public
    BOOL _isShowingTags;
    BOOL _isShowingCover;
}

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;
@property (weak, nonatomic) IBOutlet UIImageView *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@property (weak, nonatomic) IBOutlet UIImageView *markerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UILabel *secondaryTimeLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleWidthConstraint;

- (void)configure:(FeedItem * _Nonnull)item customFeed:(FeedType)isCustomFeed sizeCache:(NSMutableArray * _Nullable)sizeCache;

//@property (weak, nonatomic) NSMutableDictionary *sizeCache;
@property (weak, nonatomic) FeedItem *item;

@property (weak, nonatomic) id<ArticleCellDelegate> delegate;

- (void)showSeparator:(BOOL)showSeparator;

- (void)setupAppearance;

/* SWIPE ACTIONS */
@property (weak, nonatomic) IBOutlet UIStackView *swipeStackView;
@property (atomic, assign, getter=isSwiped) BOOL swiped;

// this method can be called inside an animation block.
- (void)setupInitialSwipeState;

@end

NS_ASSUME_NONNULL_END
