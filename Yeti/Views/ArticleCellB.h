//
//  ArticleCellB.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"
#import <DZTextKit/YetiConstants.h>

NS_ASSUME_NONNULL_BEGIN

@class ArticleCellB;

@protocol ArticleCellDelegate <NSObject>

@optional
- (void)didTapTag:(NSString *)tag;

- (void)didTapMenuButton:(id)sender forArticle:(FeedItem *)article cell:(ArticleCellB *)cell;

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

/* Menu Button */
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIButton *secondaryMenuButton;

- (IBAction)didTapMenuButton:(id)sender;

@end

NS_ASSUME_NONNULL_END
