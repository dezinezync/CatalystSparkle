//
//  PopMenuViewController.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PopMenuViewController.h"
#import <DZKit/NSArray+RZArrayCandy.h>

#import "PopMenuPresentAnimationController.h"
#import "PopMenuDismissAnimationController.h"

@interface PopMenuViewController ()

@property (nonatomic, strong) NSArray <id<PopMenuAction>> * actions;

// Max content width allowed for the content to stretch to.
@property (nonatomic, assign) CGFloat maxContentWidth;

// Tap gesture to dismiss for background view.
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureForDismissal;

// Pan gesture to highligh actions.
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureForMenu;

@property (nonatomic, strong) UISelectionFeedbackGenerator *selectionFeedback;

@end

@implementation PopMenuViewController

- (instancetype)initWithAppearance:(PopMenuAppearance *)appearance sourceView:(id)sourceView actions:(NSArray <id<PopMenuAction>> *)actions {
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.appearance = appearance ?: [PopMenuAppearance new];
        self.sourceView = sourceView;
        
        [self commonInit:actions];
        
    }
    
    return self;
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        self.appearance = [PopMenuAppearance new];
        [self commonInit:nil];
    }
    
    return self;
    
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.appearance = [PopMenuAppearance new];
        [self commonInit:nil];
    }
    
    return self;
    
}

- (void)commonInit:(NSArray <id <PopMenuAction>> *)actions {
    
    self.actions = actions ?: @[];
    
    self.backgroundView = [UIView new];
    
    UIVisualEffect *darkEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurOverlayView = [[UIVisualEffectView alloc] initWithEffect:darkEffect];
    self.blurOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.blurOverlayView.layer.cornerRadius = self.appearance.popMenuCornerRadius;
    self.blurOverlayView.layer.masksToBounds = YES;
    self.blurOverlayView.userInteractionEnabled = NO;
    
    self.containerView = [UIView new];
    
    self.contentView = [UIView new];
    
    self.actionsView = [UIStackView new];
    
    self.shouldDismissOnSelection = YES;
    self.shouldEnablePanGesture = YES;
    self.shouldEnableHaptics = YES;
    
    [self setAbsoluteSourceFrame];
    self.transitioningDelegate = self;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    self.modalPresentationCapturesStatusBarAppearance = YES;
    
    if (@available(iOS 11.0, *)) {
        
        self.selectionFeedback = [[UISelectionFeedbackGenerator alloc] init];
        
    }
    
}

- (void)loadView {
    
    [super loadView];
    
    self.view.backgroundColor = UIColor.clearColor;
    [self configureBackgroundView];
    [self configureContentView];
    [self configureActionsView];
    
}

- (void)addAction:(id<PopMenuAction>)action {
    
    if (action == nil) {
        return;
    }
    
    self.actions = [self.actions arrayByAddingObject:action];
    
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    
    return UIStatusBarAnimationFade;
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    if (self.appearance.popMenuStatusBarStyle) {
        return self.appearance.popMenuStatusBarStyle;
    }
    
    // Contrast of dimmed color style
    UIColor *color = [PopMenuDefaultAction blackOrWhiteContrastingColor:self.appearance.popMenuBackgroundColor];
    
    // above will either be black or white
    CGFloat w,a;
    [color getWhite:&w alpha:&a];
    
    if (w == 0.f) {
        return UIStatusBarStyleLightContent;
    }
    
    return UIStatusBarStyleDefault;
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    if (coordinator) {
        
        weakify(self);
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
            strongify(self);
            
            [self configureBackgroundView];
            self.contentFrame = [self calculateContentFittingFrame];
            [self setupContentConstraints];
            
        } completion:nil];
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
}

#pragma mark - Getters

- (CGFloat)maxContentWidth {
    return UIScreen.mainScreen.bounds.size.width * 0.9f;
}

- (UITapGestureRecognizer *)tapGestureForDismissal {
    
    if (_tapGestureForDismissal == nil) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewDidTap:)];
        tap.cancelsTouchesInView = NO;
        tap.delaysTouchesEnded = NO;
        
        _tapGestureForDismissal = tap;
    }
    
    return _tapGestureForDismissal;
    
}

- (UIPanGestureRecognizer *)panGestureForMenu {
    
    if (_panGestureForMenu == nil) {
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuDidPan:)];
        pan.maximumNumberOfTouches = 1;
        
        _panGestureForMenu = pan;
        
    }
    
    return _panGestureForMenu;
    
}

#pragma mark - Setters

- (void)setAbsoluteSourceFrame {
    
    UIView *sourceView = [self sourceViewAsUIView];
    
    self.absoluteSourceFrame = [sourceView convertRect:sourceView.bounds toView:nil];
    
}

#pragma mark - Geometry & Views

- (void)configureBackgroundView {
    
    self.backgroundView.frame = self.view.frame;
    self.backgroundView.backgroundColor = UIColor.clearColor;
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backgroundView addGestureRecognizer:self.tapGestureForDismissal];
    self.backgroundView.userInteractionEnabled = YES;
    
    self.backgroundView.backgroundColor = self.appearance.popMenuBackgroundColor;
    
    [self.view insertSubview:self.backgroundView atIndex:0];
    
}

- (void)configureContentView {
    
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;

    self.containerView.layer.shadowOffset = CGSizeMake(0, 1.f);
    self.containerView.layer.shadowOpacity = 0.5f;
    self.containerView.layer.shadowRadius = 20.f;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.masksToBounds = NO;
    
    self.contentView.layer.cornerRadius = self.appearance.popMenuCornerRadius;
    self.containerView.backgroundColor = UIColor.clearColor;
    
    [self.view addSubview:self.containerView];
    
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.layer.cornerRadius = self.appearance.popMenuCornerRadius;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.clipsToBounds = YES;
    
    self.contentView.backgroundColor = self.appearance.popMenuColor;
    
    [self.containerView addSubview:self.blurOverlayView];
    [self.containerView addSubview:self.contentView];
    
    [self setupContentConstraints];
}

- (void)setupContentConstraints {
    
    self.contentLeftConstraint = [self.containerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:self.contentFrame.origin.x];
    self.contentTopConstraint = [self.containerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.contentFrame.origin.y];
    self.contentWidthConstraint = [self.containerView.widthAnchor constraintEqualToConstant:self.contentFrame.origin.y];
    self.contentHeightConstraint = [self.containerView.heightAnchor constraintEqualToConstant:self.contentFrame.size.height];
    
    // Activate container view constraints
    [NSLayoutConstraint activateConstraints:@[self.contentLeftConstraint, self.contentTopConstraint, self.contentWidthConstraint, self.contentHeightConstraint]];
    
    // Activate content view constraints
    [NSLayoutConstraint activateConstraints:@[
                                              [self.contentView.leftAnchor constraintEqualToAnchor:self.containerView.leftAnchor],
                                              [self.contentView.rightAnchor constraintEqualToAnchor:self.containerView.rightAnchor],
                                              [self.contentView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
                                              [self.contentView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor]
                                              ]];
    
}

- (CGRect)contentFrame {
    
    return [self calculateContentFittingFrame];
    
}

- (CGRect)calculateContentFittingFrame {
    
    CGFloat height;
    
    if (self.actions.count >= self.appearance.popMenuActionCountForScrollable) {
        
        // Make a scroll view
        height = self.appearance.popMenuActionCountForScrollable * self.appearance.popMenuActionHeight;
        height -= 20.f;
        
    }
    else {
        height = self.actions.count * self.appearance.popMenuActionHeight;
    }
    
    CGSize size = CGSizeMake([self calculatedContentWidth], height);
    CGPoint origin = [self calculateContentOriginWithSize:size];
    
    return CGRectMake(origin.x, origin.y, size.width, size.height);
    
}

- (CGPoint)calculateContentOriginWithSize:(CGSize)size {
    
    CGRect sourceFrame = self.absoluteSourceFrame;
    
    if (CGRectEqualToRect(sourceFrame, CGRectZero)) {
    
        sourceFrame = CGRectMake(self.view.center.x - size.width / 2.f, self.view.center.y - size.height / 2.f, 0, 0);
        
    }
    
    CGFloat minContentPos = UIScreen.mainScreen.bounds.size.width * 0.05f;
    CGFloat maxContentPos = UIScreen.mainScreen.bounds.size.width * 0.95f;
    
    // Get desired content origin point
    CGFloat offsetX = (size.width - sourceFrame.size.width) / 2.f;
    CGPoint desiredOrigin = CGPointMake(sourceFrame.origin.x - offsetX, sourceFrame.origin.y);
    
    if ((desiredOrigin.x + size.width) > maxContentPos) {
        desiredOrigin.x = maxContentPos - size.width;
    }
    
    if (desiredOrigin.x < minContentPos) {
        desiredOrigin.x = minContentPos;
    }
    
    // Move content in place
    [self translateOverflowX:desiredOrigin contentSize:size];
    [self translateOverflowY:desiredOrigin contentSize:size];
    
    return desiredOrigin;
}

// Move content into view if it's overflowed in X axis.
- (void)translateOverflowX:(CGPoint)desiredOrigin contentSize:(CGSize)contentSize {
    
    CGFloat const edgePadding = 8.f;
    
    BOOL leftSide = (desiredOrigin.x - self.view.center.x) < 0;
    
    // check view overflow
    CGPoint origin = CGPointMake(leftSide ? desiredOrigin.x : desiredOrigin.x + contentSize.width, desiredOrigin.y);
    
    // Move Accordingly
    if (CGRectContainsPoint(self.view.frame, origin) == NO) {
        
        CGFloat overflowX = (leftSide ? 1 : -1) * ((leftSide ? self.view.frame.origin.x : self.view.frame.origin.x + self.view.frame.size.width) - origin.x) + edgePadding;
        
        desiredOrigin = CGPointMake(desiredOrigin.x - (leftSide ? -1 : 1) * overflowX, origin.y);
        
    }
    
}

// Move content into view if it's overflowed in Y axis.
- (void)translateOverflowY:(CGPoint)desiredOrigin contentSize:(CGSize)contentSize {
    
    CGFloat edgePadding = 0.f;
    
    // check view overflow
    CGPoint origin = CGPointMake(desiredOrigin.x, desiredOrigin.y + contentSize.height);
    
    if (@available(iOS 11.0, *)) {
        edgePadding = UIApplication.sharedApplication.keyWindow ? UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom : 8.f;
    }
    else {
        edgePadding = 8.f;
    }
    
    // check content inside of view or not
    if (CGRectContainsPoint(self.view.frame, origin) == NO) {
        
        CGFloat overflowY = origin.y - self.view.frame.size.height + edgePadding;
        
        desiredOrigin = CGPointMake(desiredOrigin.x, desiredOrigin.y - overflowY);
        
    }
    
}


- (UIView *)sourceViewAsUIView {
    
    if (self.sourceView == nil) {
        return nil;
    }
    
    // Check if UIBarButtonItem
    if ([self.sourceView isKindOfClass:UIBarButtonItem.class]) {
        UIBarButtonItem *sourceBarButtonItem = self.sourceView;
        
        UIView *buttonView = [sourceBarButtonItem valueForKey:@"view"];
        
        if (buttonView) {
            return buttonView;
        }
    }
    
    if ([self.sourceView isKindOfClass:UIView.class]) {
        return self.sourceView;
    }
    
    return nil;
    
}

- (CGFloat)calculatedContentWidth {
    
    CGFloat contentFitWidth = 0.f;
    contentFitWidth += kPopMenuDefaultTextLeftPadding * 2.f;
    
    // calculate the widest width from action titles to determine the width
    id <PopMenuAction> action = [self.actions rz_reduce:^id(id<PopMenuAction> prev, id<PopMenuAction> current, NSUInteger idx, NSArray *array) {
        
        return prev.title.length < current.title.length ? current : prev;
        
    }];
    
    if (action == nil) {
        return MIN(contentFitWidth, self.maxContentWidth);
    }
    
    UILabel *sizingLabel = [UILabel new];
    sizingLabel.text = action.title;
    sizingLabel.font = action.font ?: self.appearance.popMenuFont;
    
    CGFloat desiredWidth = [sizingLabel sizeThatFits:self.view.bounds.size].width;
    
    contentFitWidth += desiredWidth;
    contentFitWidth += action.iconWidthHeight;
    
    return MIN(contentFitWidth, self.maxContentWidth);
    
}

- (void)configureActionsView {
    
    self.actionsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionsView.axis = UILayoutConstraintAxisVertical;
    self.actionsView.alignment = UIStackViewAlignmentFill;
    self.actionsView.distribution = UIStackViewDistributionFillEqually;
    
    // configure each action
    [self.actions enumerateObjectsUsingBlock:^(id<PopMenuAction>  _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
       
        action.font = self.appearance.popMenuFont;
        action.tintColor = self.appearance.popMenuTextColor ? self.appearance.popMenuTextColor : action.color;
        action.cornerRadius = self.appearance.popMenuCornerRadius / 2.f;
        [action renderActionView];
        
        UITapGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuDidTap:)];
        tapper.delaysTouchesEnded = NO;
        
        [action.view addGestureRecognizer:tapper];
        
        [self.actionsView addArrangedSubview:action.view];
        
    }];
    
    // Check if whether to add scroll view or not
    if (self.actions.count >= self.appearance.popMenuActionCountForScrollable) {
        
        // Scrollable Actions
        UIScrollView *scrollView = [UIScrollView new];
        scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollView.showsHorizontalScrollIndicator = NO;
        scrollView.showsVerticalScrollIndicator = self.appearance.popMenuScrollIndicatorHidden;
        scrollView.indicatorStyle = self.appearance.popMenuScrollIndicatorStyle;
        scrollView.contentSize = CGSizeMake(0.f, self.appearance.popMenuActionHeight * self.actions.count);
        
        [scrollView addSubview:self.actionsView];
        [self.contentView addSubview:scrollView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [scrollView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
                                                  [scrollView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
                                                  [scrollView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
                                                  [scrollView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
                                                  ]];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.actionsView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
                                                  [self.actionsView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
                                                  [self.actionsView.topAnchor constraintEqualToAnchor:scrollView.topAnchor],
                                                  [self.actionsView.heightAnchor constraintEqualToConstant:scrollView.contentSize.height]
                                                  ]];
        
    }
    else {
        // Not scrollable
        
        [self.actionsView addGestureRecognizer:self.panGestureForMenu];
        [self.contentView addSubview:self.actionsView];
        
        [NSLayoutConstraint activateConstraints:@[
                                                  [self.actionsView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
                                                  [self.actionsView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
                                                  [self.actionsView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4.f],
                                                  [self.actionsView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4.f]
                                                  ]];
        
    }
}

- (BOOL)touchedInsideContent:(CGPoint)location {
    
    return CGRectContainsPoint(self.containerView.frame, location);
    
}

//  Get the gesture associated action index.
- (NSInteger)associatedActionIndex:(UIGestureRecognizer *)sender {
    
    NSUInteger index = NSNotFound;
    
    if ([self touchedInsideContent:[sender locationInView:self.view]] == NO) {
        return index;
    }
    
    // check which action is associted
    CGPoint location = [sender locationInView:self.actionsView];
    
    // Get associated index for touch location
    UIView *touchedView = [self.actionsView.arrangedSubviews rz_reduce:^id(__kindof UIView *prev, __kindof UIView *current, NSUInteger idx, NSArray *array) {
       
        if (CGRectContainsPoint(current.frame, location)) {
            return current;
        }
        
        return prev;
        
    }];
    
    if (touchedView != nil) {
        index = [self.actionsView.arrangedSubviews indexOfObject:touchedView];
    }
    
    return index;
    
}

#pragma mark - Actions

- (void)actionDidSelect:(NSInteger)index animated:(BOOL)animated {
    
    id <PopMenuAction> action = self.actions[index];
    
    [action actionSelected:animated];
    
    if (self.shouldEnableHaptics) {
        if(@available(iOS 11.0, *)) {
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [generator prepare];
            [generator impactOccurred];
        }
    }
    
    // notify delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(popMenuDidSelectItem:index:action:)]) {
        [self.delegate popMenuDidSelectItem:self index:index action:action];
    }
    
    // if should dimiss upon selection
    if (self.shouldDismissOnSelection) {
        [self dismissSelf:index];
    }
    
}

- (void)unhighlightActionsExcept:(id<PopMenuAction>)action {
    
    // Unhighlight for other actions
    [self.actions enumerateObjectsUsingBlock:^(id<PopMenuAction>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (action == obj) {
            return;
        }
        
        obj.highlighted = NO;
        
    }];
    
}

- (void)highlightAction:(id <PopMenuAction>)action {
    
    if (action == nil) {
        [self unhighlightActionsExcept:action];
        
        return;
    }
    
    // Must not be already highlighted
    if (action.isHighlighted) {
        return;
    }
    
    [self.selectionFeedback prepare];
    [self.selectionFeedback selectionChanged];
    
    // Highlight current action view
    action.highlighted = YES;
    
    [self unhighlightActionsExcept:action];
    
}

- (void)menuDidPan:(UIPanGestureRecognizer *)sender {
    
    if (self.shouldEnablePanGesture == NO) {
        return;
    }
    
    NSUInteger index = [self associatedActionIndex:sender];
    
    if (index == NSNotFound) {
        return;
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            
            id <PopMenuAction> action = [self.actions objectAtIndex:index];
            
            [self highlightAction:action];
            
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            // Unhighlight all actions
            [self unhighlightActionsExcept:nil];
            
            // Trigger action selection.
            [self actionDidSelect:index animated:NO];
        }
            break;
        default:
        {
            // Unhighlight all actions
            [self unhighlightActionsExcept:nil];
        }
            break;
    }
    
}

- (void)menuDidTap:(UITapGestureRecognizer *)sender {
    
    UIView *attachedView = sender.view;
    NSUInteger index = NSNotFound;
    
    id <PopMenuAction> action = [self.actions rz_reduce:^id(id<PopMenuAction> prev, id<PopMenuAction> current, NSUInteger idx, NSArray *array) {
        
        if (current.view == attachedView) {
            return current;
        }
        
        return prev;
        
    }];
    
    DDLogDebug(@"State: %@", @(sender.state));
    
    switch (sender.state) {
        // not supported for UITapGestureRecgnizer
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            [self highlightAction:action];
        
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            
            [self unhighlightActionsExcept:nil];
            
            if (action) {
                
                if (action.didSelect) {
                    action.didSelect(action);
                }
                
                index = [self.actions indexOfObject:action];
            }
            
            if (index != NSNotFound && self.delegate && [self.delegate respondsToSelector:@selector(popMenuDidSelectItem:index:action:)]) {
                
                [self.delegate popMenuDidSelectItem:self index:index action:action];
                
            }
            
            if (self.shouldDismissOnSelection) {
                [self dismissSelf:index];
            }
        }
            break;
        default:
            break;
    }
    
}

- (void)backgroundViewDidTap:(UITapGestureRecognizer *)sender {
    
    if (sender == self.tapGestureForDismissal) {
        
        if ([self touchedInsideContent:[sender locationInView:self.view]] == YES) {
            return;
        }
        
        [self dismissSelf:NSNotFound];
        
    }
    
}

- (void)dismissSelf:(NSInteger)index {
    
    id<PopMenuViewControllerDelegate> delegate = self.delegate;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        if (delegate && [delegate respondsToSelector:@selector(didDismiss:)]) {
            [self.delegate didDismiss:index];
        }
        
    }];
    
}

#pragma mark - <UIViewControllerTransitioningDelegate>

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {

    return [[PopMenuPresentAnimationController alloc] initWithSourceFrame:self.absoluteSourceFrame];
    
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    return [[PopMenuDismissAnimationController alloc] initWithSourceFrame:self.absoluteSourceFrame];

}

@end
