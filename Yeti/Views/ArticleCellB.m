//
//  ArticleCellB.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleCellB.h"
#import "NSDate+DateTools.h"
#import "NSString+HTML.h"
#import "Paragraph.h"
#import "CheckWifi.h"

#import "YetiConstants.h"
#import "FeedsManager.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZNetworking/UIImageView+ImageLoading.h>

#import "YetiThemeKit.h"

NSString *const kiPadArticleCell = @"com.yeti.cell.iPadArticleCell";

@interface ArticleCellB ()

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;
@property (nonatomic, readonly) CGSize estimatedSize;
@property (weak, nonatomic) IBOutlet UIStackView *contentStackView;

@end

@implementation ArticleCellB

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Initialization code
    self.contentView.frame = self.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    CALayer *iconLayer = self.faviconView.layer;
    iconLayer.borderWidth = 1/[UIScreen mainScreen].scale;
    
    if (self.selectedBackgroundView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        self.selectedBackgroundView = view;
    }
    
    if (self.backgroundView == nil) {
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        view.alpha = 0.f;
        self.backgroundView = view;
    }
    
    [self setupAppearance];
}

- (void)setupAppearance {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.faviconView.layer.borderColor = [(YetiTheme *)[YTThemeKit theme] borderColor].CGColor;
    
    self.titleLabel.textColor = theme.titleColor;
    self.timeLabel.textColor = theme.subtitleColor;
    self.authorLabel.textColor = theme.subtitleColor;
    
    self.backgroundColor = theme.cellColor;
    
    self.backgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    self.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    self.titleLabel.text = nil;
    self.authorLabel.text = nil;
    self.timeLabel.text = nil;
    self.faviconView.image = nil;
    
    self.backgroundView.alpha = 0.f;
    
}

- (void)setHighlighted:(BOOL)highlighted {
    
    self.backgroundView.alpha = highlighted ? 1.f : 0.f;
    
}

- (void)setSelected:(BOOL)selected {
    
    self.selectedBackgroundView.alpha = selected ? 1.f : 0.f;
    
}


#pragma mark - Config

- (void)configure:(FeedItem *)item customFeed:(BOOL)isCustomFeed sizeCache:(nonnull NSMutableDictionary *)sizeCache {
    
    self.sizeCache = sizeCache;
    self.item = item;
    self.titleLabel.text = item.articleTitle;
    
    if (item.author) {
        if ([item.author isKindOfClass:NSString.class]) {
            self.authorLabel.text = [(item.author ?: @"") stringByStrippingHTML];
        }
        else {
            self.authorLabel.text = [([item.author valueForKey:@"name"] ?: @"") stringByStrippingHTML];
        }
    }
    else {
        self.authorLabel.text = @"Unknown";
    }
    
    if (item.blogTitle) {
        self.authorLabel.text = [self.authorLabel.text stringByAppendingFormat:@" - %@", item.blogTitle];
    }
    
    self.timeLabel.text = [item.timestamp shortTimeAgoSinceNow];
    self.timeLabel.accessibilityLabel = [item.timestamp timeAgoSinceNow];
    
    Feed *feed = [MyFeedsManager feedForID:item.feedID];
    
    if (feed) {
        NSString *url = [feed faviconURI];
        
        if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
            @try {
                weakify(self);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    strongify(self);
                    [self.faviconView il_setImageWithURL:formattedURL(@"%@", url)];
                });
            }
            @catch (NSException *exc) {
                // this catches the -[UIImageView _updateImageViewForOldImage:newImage:] crash
                DDLogWarn(@"ArticleCell setImage: %@", exc);
            }
        }
    }
    
    self.titleLabel.accessibilityValue = [self.titleLabel.text stringByReplacingOccurrencesOfString:@" | " withString:@" by "];
    
    if (([Paragraph languageDirectionForText:item.articleTitle] == NSLocaleLanguageDirectionRightToLeft)
        || (item.summary && [Paragraph languageDirectionForText:item.summary] == NSLocaleLanguageDirectionRightToLeft)) {
        
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.authorLabel.textAlignment = NSTextAlignmentRight;
        
    }
    
}

#pragma mark -

-  (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {

    UICollectionViewLayoutAttributes *attributes = [layoutAttributes copy];

    CGRect frame = attributes.frame;
    frame.size = self.estimatedSize;

    attributes.frame = frame;

    return attributes;

}

- (CGSize)estimatedSize {
    
    if (self.sizeCache
        && self.item
        && self.sizeCache[self.item.identifier.stringValue]) {
        
        CGSize size = CGSizeFromString(self.sizeCache[self.item.identifier.stringValue]);
        
        return size;
        
    }
    
    UICollectionView *collectionView;
    
    if (self.superview) {
        collectionView = (UICollectionView *)[self superview];
    }
    else {
        UISplitViewController *splitVC = (UISplitViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        UINavigationController *nav = [[splitVC viewControllers] lastObject];
        UICollectionViewController *cv = [[nav viewControllers] lastObject];
        
        collectionView = cv.collectionView;
    }
    
    CGSize contentSize = collectionView.contentSize;
    
    CGFloat width = contentSize.width;
    
    /*
     |- 16 - (cell) - 16 - (cell) - 16 -|
     */
    
    // get actual values from the layout
    CGFloat padding = [(UICollectionViewFlowLayout *)[collectionView collectionViewLayout] minimumInteritemSpacing];
    CGFloat totalPadding = padding * 3.f;
    
    CGFloat usableWidth = width - totalPadding;
    
    CGFloat cellWidth = usableWidth;
    
    if (usableWidth > 601.f) {
        // the remainder will be absorbed by the interimSpacing
        cellWidth = floor(usableWidth / 2.f);
    }
    else {
        cellWidth = width - (padding * 2.f);
    }
    
    [self.contentView layoutIfNeeded];
    
    CGSize fittingSize = CGSizeZero;
    fittingSize.width = cellWidth;
    
    CGSize proposedSize = [self.contentView systemLayoutSizeFittingSize:CGSizeMake(fittingSize.width, 200.f) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    
    fittingSize.height = proposedSize.height;
    
//    fittingSize.height += 12.f * 2.f;
    
    if (self.sizeCache && self.item && proposedSize.height <= 200.f) {
        self.sizeCache[self.item.identifier.stringValue] = NSStringFromCGSize(fittingSize);
    }
    
    return fittingSize;
    
}

@end
