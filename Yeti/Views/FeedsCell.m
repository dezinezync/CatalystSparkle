//
//  FeedsCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsCell.h"
#import <DZKit/NSString+Extras.h>
#import <DZNetworking/UIImageView+ImageLoading.h>

#import "FeedsManager.h"
#import "YetiThemeKit.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "TypeFactory.h"
#import "NSString+ImageProxy.h"

NSString *const kFeedsCell = @"com.yeti.cells.feeds";

@interface FeedsCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stackLeading;
@property (weak, nonatomic) Feed * feed;

@end

static void *KVO_UNREAD = &KVO_UNREAD;

@implementation FeedsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.faviconView.contentMode = UIViewContentModeCenter;
    self.faviconView.image = [[UIImage imageNamed:@"nofavicon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.clipsToBounds = YES;
    
    self.countLabel.font = [[[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleSubheadline] scaledFontForFont:[UIFont monospacedDigitSystemFontOfSize:14.f weight:UIFontWeightMedium]];
    self.countLabel.layer.cornerRadius = ceil(self.countLabel.bounds.size.height / 2.f);
    self.countLabel.layer.masksToBounds = YES;
    
    self.indentationWidth = 28.f;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.backgroundColor = theme.cellColor;

    self.titleLabel.textColor = theme.titleColor;
    self.titleLabel.font = [TypeFactory.shared titleFont];
    
    self.countLabel.backgroundColor = theme.unreadBadgeColor;
    self.countLabel.textColor = theme.unreadTextColor;
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    self.selectedBackgroundView = selected;
    
    self.preservesSuperviewLayoutMargins = NO;
    self.separatorInset = UIEdgeInsetsMake(0, 40.f, 0, 0);
}

- (void)prepareForReuse
{
    [self removeObservorInfo];
    
    [super prepareForReuse];
    
    self.feed = nil;
    
    [self.faviconView il_cancelImageLoading];
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.cacheImage = NO;
    self.faviconView.cachedSuffix = nil;
    self.faviconView.image = [[UIImage imageNamed:@"nofavicon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.indentationLevel = 0;
    self.stackLeading.constant = 8.f;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil || (self.superview && self.superview != newSuperview)) {
        [self removeObservorInfo];
    }
    
    [super willMoveToSuperview:newSuperview];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    NSTimeInterval duration = animated ? 0.2 : 0;
    
    weakify(self);
    [UIView animateWithDuration:duration animations:^{
        strongify(self);
        
        self.backgroundColor = highlighted ? [theme.tintColor colorWithAlphaComponent:0.2f] : theme.cellColor;
        self.countLabel.backgroundColor = theme.unreadBadgeColor;
    }];
}

- (void)dealloc
{
    [self removeObservorInfo];
}

#pragma mark - Setter

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    self.contentView.backgroundColor = backgroundColor;
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:UIStackView.class]) {
            UIColor *color = backgroundColor;
            CGFloat alpha;
            
            [color getRed:nil green:nil blue:nil alpha:&alpha];
            if (alpha < 1.f)
                color = [UIColor clearColor];
            
            [[(UIStackView *)subview arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.backgroundColor = color;
            }];
        }
        else {
            subview.backgroundColor = backgroundColor;
        }
    }
    
    if (UIAccessibilityIsInvertColorsEnabled() == YES) {
        Theme *theme = [YTThemeKit theme];
        self.faviconView.backgroundColor = theme.isDark ? UIColor.whiteColor : UIColor.blackColor;
    }
}

#pragma mark -

- (void)configure:(Feed *)feed
{
    
    [self removeObservorInfo];
    
    BOOL registers = YES;
    
    if (feed.folderID != nil) {
        self.indentationLevel = 1;
        self.stackLeading.constant = 8.f + (self.indentationWidth * self.indentationLevel);
        
        self.separatorInset = UIEdgeInsetsMake(0, 40.f + self.indentationWidth, 0, 0);
        
        [self setNeedsUpdateConstraints];
        [self layoutIfNeeded];
        
        registers = NO;
    }
    else {
        self.separatorInset = UIEdgeInsetsMake(0, 40.f, 0, 0);
    }
    
    self.faviconView.cacheImage = YES;
    self.faviconView.cachedSuffix = @"-feedFavicon";
    
    self.feed = feed;
    
    self.titleLabel.text = feed.displayTitle;
    self.countLabel.text = (feed.unread ?: @0).stringValue;
    
    NSString *url = [feed faviconURI];
    
    if (url && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {
        
        url = [url pathForImageProxy:NO maxWidth:24.f quality:0.f];
        
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
    
    [self setupObservors];
}

#pragma mark - a11y

- (NSString *)accessibilityLabel {
    NSInteger count = [self.countLabel.text integerValue];
    NSString *title = self.titleLabel.text;
    
    if ([title isEqualToString:@"Bookmarks"]) {
        return formattedString(@"%@. %@ article%@", title, @(count), count == 1 ? @"" : @"s");
    }
    
    return formattedString(@"%@. %@ unread article%@", title, @(count), count == 1 ? @"" : @"s");
}

#pragma mark - KVO

- (void)setupObservors {
    
    if (self.feed) {
        [self.feed addObserver:self forKeyPath:propSel(unread) options:NSKeyValueObservingOptionNew context:KVO_UNREAD];
    }
    
}

- (void)removeObservorInfo {
    
    if (self.feed && self.feed.observationInfo != nil) {
        
        NSArray *observingObjects = [(id)(self.feed.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [self.feed removeObserver:self forKeyPath:propSel(unread) context:KVO_UNREAD];
            } @catch (NSException *exc) {}
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context == KVO_UNREAD) {
        [self updateFolderCount];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

- (void)updateFolderCount {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateFolderCount) withObject:nil waitUntilDone:NO];
        
        return;
    }
    
    NSNumber *totalUnread = self.feed ? self.feed.unread : @(0);
    
    self.countLabel.text = [(totalUnread ?: @0) stringValue];
}

@end
