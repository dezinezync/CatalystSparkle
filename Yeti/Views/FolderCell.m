//
//  FolderCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FolderCell.h"
#import "YetiThemeKit.h"
#import "FolderDrop.h"

#import <DZKit/NSString+Extras.h>
#import <DZNetworking/UIImageView+ImageLoading.h>

#import "FeedsManager.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <DZKit/NSArray+RZArrayCandy.h>

static void *KVO_UNREAD = &KVO_UNREAD;

NSString *const kFolderCell = @"com.yeti.cells.folder";

@interface FolderCell () <UIDropInteractionDelegate>

@property (weak, nonatomic) Folder * folder;
@property (weak, nonatomic) UIDropInteraction *dropInteraction;

@property (weak, nonatomic) id <FolderDrop> dropDelegate;

@end

@implementation FolderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.faviconView.contentMode = UIViewContentModeCenter;
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
    
    self.folder = nil;
    
    [self.faviconView il_cancelImageLoading];
    
    self.faviconView.layer.cornerRadius = 4.f;
    self.faviconView.cacheImage = NO;
    self.faviconView.cachedSuffix = nil;
    self.faviconView.image = [[UIImage imageNamed:@"nofavicon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    self.indentationLevel = 0;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.selectedBackgroundView.backgroundColor = [theme.tintColor colorWithAlphaComponent:0.35f];
    
    if (self.dropInteraction) {
        [self removeInteraction:self.dropInteraction];
        self.dropInteraction = nil;
    }
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

- (void)configureFolder:(Folder *)folder {
    [self configureFolder:folder dropDelegate:nil];
}

- (void)configureFolder:(Folder *)folder dropDelegate:(id <FolderDrop>)dropDelegate {
    
    [self removeObservorInfo];
    
    self.folder = folder;
    
    self.titleLabel.text = folder.title;
    self.faviconView.layer.cornerRadius = 0.f;
    [self updateFolderCount];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.faviconView.image = [[UIImage imageNamed:([folder isExpanded] ? @"folder_open" : @"folder")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    if (dropDelegate != nil) {
        UIDropInteraction * dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        self.dropDelegate = dropDelegate;
        [self addInteraction:dropInteraction];
        
        _dropInteraction = dropInteraction;
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

//- (NSString *)accessibilityValue {
//    if ([self.object isKindOfClass:Folder.class]) {
//        return @"Folder";
//    }
//
//    return [super accessibilityValue];
//}

- (NSString *)accessibilityHint {
    if (self.folder) {
        
        if ([self.folder isExpanded]) {
            return @"Tap to Close Folder";
        }
        
        return @"Tap to Open Folder";
    }
    
    return [super accessibilityValue];
}

#pragma mark - KVO

- (void)setupObservors {
    
    if (self.folder) {
        [self.folder addObserver:self forKeyPath:propSel(unreadCount) options:NSKeyValueObservingOptionNew context:KVO_UNREAD];
    }
    
}

- (void)removeObservorInfo {
    
    if (self.folder && self.folder.observationInfo != nil) {
        
        NSArray *observingObjects = [(id)(self.folder.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [self.folder removeObserver:self forKeyPath:propSel(unreadCount)];
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
        weakify(self);
        asyncMain(^{
            strongify(self);
            
            [self updateFolderCount];
        })
        
        return;
    }
    
    NSNumber *totalUnread = self.folder ? self.folder.unreadCount : @(0);
    
    self.countLabel.text = [(totalUnread ?: @0) stringValue];
}

#pragma mark - Drop

- (BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session {
    NSArray *typeIdentifiers = @[(__bridge NSString *)kUTTypeUTF8PlainText];
    
    return ([[session items] count]
            && [session hasItemsConformingToTypeIdentifiers:typeIdentifiers]);
}

- (UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(nonnull id<UIDropSession>)session {
    
    CGPoint dropLocation = [session locationInView:self];
    
    UIDropProposal *proposal = nil;
    
    if (CGRectContainsPoint(self.bounds, dropLocation) && self.dropDelegate != nil) {
        proposal = [[UIDropProposal alloc] initWithDropOperation:UIDropOperationMove];
    }
    else {
        proposal = [[UIDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
    }
    
    return proposal;
    
}

- (void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session {
    
    weakify(self);
    
    [session loadObjectsOfClass:NSString.class completion:^(NSArray<__kindof id<NSItemProviderReading>> * _Nonnull objects) {
        
        [objects enumerateObjectsUsingBlock:^(__kindof id<NSItemProviderReading>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            strongify(self);
            
            [self.dropDelegate moveFeed:obj toFolder:self.folder];
        }];
        
    }];
    
}

@end