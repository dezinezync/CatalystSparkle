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
#import "TypeFactory.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <DZKit/NSArray+RZArrayCandy.h>

static void *KVO_UNREAD = &KVO_UNREAD;

NSString *const kFolderCell = @"com.yeti.cells.folder";

@interface FolderCell () <UIDropInteractionDelegate>

@property (strong, nonatomic) Folder * folder;
@property (weak, nonatomic) UIDropInteraction *dropInteraction;

@property (weak, nonatomic) id <FolderDrop> dropDelegate;

@end

@implementation FolderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.faviconView.contentMode = UIViewContentModeCenter;
    
    if (@available (iOS 13, *)) {
        self.faviconView.image = [UIImage systemImageNamed:@"folder.fill"];
    }
    else {
        self.faviconView.image = [[UIImage imageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
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
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapIcon:)];
    [self.faviconView addGestureRecognizer:tap];
    
    self.preservesSuperviewLayoutMargins = false;
    self.separatorInset = UIEdgeInsetsMake(0, 40.f, 0, 0);
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
    self.titleLabel.text = nil;
    self.countLabel.text = nil;
    
    if (@available (iOS 13, *)) {
        self.faviconView.image = [UIImage systemImageNamed:@"folder.fill"];
    }
    else {
        self.faviconView.image = [[UIImage imageNamed:@"folder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
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
    
    UIImage *image = nil;
    
    if (@available (iOS 13, *)) {
        
        if (folder.isExpanded == YES) {
            image = [UIImage systemImageNamed:@"folder"];
        }
        else {
            image = [UIImage systemImageNamed:@"folder.fill"];
        }
        
    }
    else {
        image = [[UIImage imageNamed:([folder isExpanded] ? @"folder_open" : @"folder")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    self.faviconView.image = image;
    
    if (dropDelegate != nil) {
        UIDropInteraction * dropInteraction = [[UIDropInteraction alloc] initWithDelegate:self];
        self.dropDelegate = dropDelegate;
        [self addInteraction:dropInteraction];
        
        _dropInteraction = dropInteraction;
    }
    
    [self setupObservors];
}

- (void)didTapIcon:(id)sender {
    
    if (self.interactionDelegate) {
        [self.interactionDelegate didTapFolderIcon:self.folder cell:self];
    }
    
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

- (NSString *)accessibilityHint {
    if (self.folder) {
        
        if ([self.folder isExpanded]) {
            return @"Tap to Close Folder";
        }
        
        return @"Tap to Open Folder";
    }
    
    return [super accessibilityValue];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGFloat radius = 48.f;
    
    // For the y-offset, we divide by 2 to prevent the touch from overflowing
    // to the adjascent rows.
    CGRect frame = CGRectInset(self.faviconView.bounds, -radius, -radius/2);
    
    if (CGRectContainsPoint(frame, point)) {
        return self.faviconView;
    }
    
    return [super hitTest:point withEvent:event];
}

#pragma mark - KVO

- (void)setupObservors {
    
    if (self.folder) {
        [self.folder addObserver:self forKeyPath:propSel(unreadCount) options:NSKeyValueObservingOptionNew context:KVO_UNREAD];
    }
    
}

- (void)removeObservorInfo {
    
    if (self.folder && self.folder.observationInfo != nil) {
        
        @try {
            [self.folder removeObserver:self forKeyPath:propSel(unreadCount) context:KVO_UNREAD];
        } @catch (NSException *exc) {
            
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
