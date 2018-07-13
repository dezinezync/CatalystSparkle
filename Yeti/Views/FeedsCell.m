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

NSString *const kFeedsCell = @"com.yeti.cells.feeds";

@interface FeedsCell () {
    BOOL _configuredForFolder;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *stackLeading;
@property (weak, nonatomic) NSObject * object;

@end

static void *KVO_UNREAD = &KVO_UNREAD;

@implementation FeedsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.faviconView.image = [[UIImage imageNamed:@"nofavicon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.clipsToBounds = YES;
    
    self.countLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightBold];
    self.countLabel.layer.cornerRadius = ceil(self.countLabel.bounds.size.height / 2.f);
    self.countLabel.layer.masksToBounds = YES;
    
    self.indentationWidth = 28.f;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.backgroundColor = theme.cellColor;

    self.titleLabel.textColor = theme.titleColor;
    
    self.countLabel.backgroundColor = theme.unreadBadgeColor;
    self.countLabel.textColor = theme.unreadTextColor;
    
    UIView *selected = [UIView new];
    selected.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    self.selectedBackgroundView = selected;
}

- (void)prepareForReuse
{
    [self removeObservorInfo];
    
    [super prepareForReuse];
    
    self.object = nil;
    
    [self.faviconView il_cancelImageLoading];
    
    self.faviconView.layer.cornerRadius = 4.f;
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

- (void)removeObservorInfo {
    
    if (MyFeedsManager.observationInfo != nil) {
        
        NSArray *observingObjects = [(id)(MyFeedsManager.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [MyFeedsManager removeObserver:self forKeyPath:propSel(unread)];
            } @catch (NSException *exc) {}
        }
    }
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
}

- (void)setObject:(id)object {
    
    if (object == nil) {
        [self removeObservorInfo];
    }
    
    _object = object;
}

#pragma mark -

- (void)configure:(Feed *)feed
{
    
    [self removeObservorInfo];
    
    BOOL registers = YES;
    
    if (feed.folderID != nil) {
        self.indentationLevel = 1;
        self.stackLeading.constant = 8.f + (self.indentationWidth * self.indentationLevel);
        
        [self setNeedsUpdateConstraints];
        [self layoutIfNeeded];
        
        registers = NO;
    }
    
    self.object = feed;
    
    self.titleLabel.text = feed.title;
    self.countLabel.text = (feed.unread ?: @0).stringValue;
    
    NSString *url = [feed faviconURI];
    
    if (url && [url isKindOfClass:NSString.class] && ![url isBlank]) {
        weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            strongify(self);
            [self.faviconView il_setImageWithURL:formattedURL(@"%@", url)];
        });
    }
    
//    if (registers) {
//        [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:KVO_UNREAD];
//    }
}

- (void)configureFolder:(Folder *)folder {
    
    [self removeObservorInfo];
    
    _configuredForFolder = YES;
    
    self.object = folder;
    
    self.titleLabel.text = folder.title;
    self.faviconView.layer.cornerRadius = 0.f;
    [self updateFolderCount];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.faviconView.image = [[UIImage imageNamed:([folder isExpanded] ? @"folder_open" : @"folder")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
//    [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:KVO_UNREAD];
}

- (NSString *)accessibilityValue {
    if ([self.object isKindOfClass:Folder.class]) {
        return @"Folder";
    }
    
    return [super accessibilityValue];
}

- (NSString *)accessibilityHint {
    if ([self.object isKindOfClass:Folder.class]) {
        Folder *folder = (Folder *)[self object];
        
        if ([folder isExpanded]) {
            return @"Close Folder";
        }
        
        return @"Open Folder";
    }
    
    return [super accessibilityValue];
}

#pragma mark - KVO

- (void)updateFolderCount {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        asyncMain(^{
            strongify(self);
            
            [self updateFolderCount];
        })
        
        return;
    }
    
    NSArray <Feed *> *feeds = [(Folder *)self.object feeds];
    NSNumber *totalUnread = (NSNumber *)[feeds rz_reduce:^id(NSNumber *prev, Feed *current, NSUInteger idx, NSArray *array) {
        
        return @([prev integerValue] + (current.unread ?: @0).integerValue);
        
    } initialValue:@(0)];
    
    self.countLabel.text = [totalUnread stringValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (context == KVO_UNREAD && [keyPath isEqualToString:propSel(unread)]) {
        
        NSSet *oldSet = nil, *newSet = nil;
        
        if ([[change valueForKey:@"old"] isKindOfClass:NSArray.class]) {
            oldSet = [[NSSet setWithArray:[[change valueForKey:@"old"] rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID;
            }]] mutableCopy];
        }
        
        if ([[change valueForKey:@"new"] isKindOfClass:NSArray.class]) {
            newSet = [[NSSet setWithArray:[[change valueForKey:@"new"] rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID;
            }]] mutableCopy];
        }
        
        NSMutableSet *diffNew = newSet.mutableCopy;
        [diffNew minusSet:oldSet];
        DDLogDebug(@"diffNew set: %@", diffNew);
        
        NSMutableSet *diffOld = oldSet.mutableCopy;
        [diffOld minusSet:newSet];
        DDLogDebug(@"diffOld set: %@", diffNew);
        
        NSArray *diffedNew = [diffNew allObjects];
        NSArray *diffedOld = [diffOld allObjects];
        
        if (diffedNew.count == 0 && diffedOld.count == 0) {
            // the next block will be indeterminate.
            // therefore, loop through each block
            // and apply the unread counts manually.
            
            if ([self.object isKindOfClass:Folder.class]) {
                
                Folder *folder = (Folder *)[self object];
                
                __block BOOL changed = NO;
                
                [folder.feeds enumerateObjectsUsingBlock:^(Feed *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([oldSet containsObject:obj.feedID]) {
                        
                        @try {
                            obj.unread = @([[MyFeedsManager.unread rz_filter:^BOOL(FeedItem *objx, NSUInteger idxx, NSArray *array) {
                                return [objx.feedID isEqualToNumber:obj.feedID];
                            }] count]);
                        }
                        @catch (NSException *exc) {}
                        
                        changed = YES;
                        
                    }
                    
                }];
                
                if (changed) {
                    [self updateFolderCount];
                }
                 
            }
            else {
                Feed *feed = (Feed *)[self object];
                
                if (feed) {
                    @try {
                        feed.unread = @([[MyFeedsManager.unread rz_filter:^BOOL(FeedItem *objx, NSUInteger idxx, NSArray *array) {
                            return [objx.feedID isEqualToNumber:feed.feedID];
                        }] count]);
                    }
                    @catch (NSException *exc) {}
                    
                    weakify(self);
                    
                    asyncMain(^{
                        strongify(self);
                        
                        self.countLabel.text = [feed.unread stringValue];
                    });
                }
            }
            
            return;
            
        }
        
        // now check if our object is in the diff set
        if ([self.object isKindOfClass:Folder.class]) {
            
            __block BOOL changed = NO;
            
            [[(Folder *)self.object feeds] enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if ([diffedNew containsObject:obj.feedID]) {
                    obj.unread = @(obj.unread.integerValue + 1);
                    
                    if (!changed) {
                        changed = YES;
                    }
                }
                
                if ([diffedOld containsObject:obj.feedID]) {
                    obj.unread = @(MAX(0, obj.unread.integerValue - 1));
                    
                    if (!changed) {
                        changed = YES;
                    }
                }
                
            }];
            
            if (changed) {
                [self updateFolderCount];
            }
            
        }
        else {
            
            BOOL changed = NO;
            
            Feed *feed = (Feed *)[self object];
            
            if ([diffedNew containsObject:feed.feedID]) {
                NSInteger unread = [feed.unread integerValue];
                [feed setUnread:@(unread + 1)];
                
                if (!changed) {
                    changed = YES;
                }
            }
            
            if ([diffedOld containsObject:[(Feed *)self.object feedID]]) {
                NSInteger unread = [feed.unread integerValue];
                [feed setUnread:@(MAX(0, unread - 1))];
                
                if (!changed) {
                    changed = YES;
                }
            }
            
            if (changed) {
                weakify(self);
                
                asyncMain(^{
                    strongify(self);
                    
                    self.countLabel.text = [feed.unread stringValue];
                });
            }
            
        }
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
