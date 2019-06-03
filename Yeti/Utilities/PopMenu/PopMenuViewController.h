//
//  PopMenuViewController.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopMenuAppearance.h"
#import "PopMenuDefaultAction.h"

NS_ASSUME_NONNULL_BEGIN

@class PopMenuViewController;

@protocol PopMenuViewControllerDelegate <NSObject>

@optional

- (void)didDismiss:(NSInteger)selected;

- (void)popMenuDidSelectItem:(PopMenuViewController *)controller index:(NSUInteger)index action:(id <PopMenuAction>)action;

@end

@interface PopMenuViewController : UIViewController <UIViewControllerTransitioningDelegate>

- (instancetype)initWithAppearance:(PopMenuAppearance *)appearance sourceView:(id)sourceView actions:(NSArray <id<PopMenuAction>> *)actions;

- (void)addAction:(id<PopMenuAction>)action;

@property (nonatomic, weak) id<PopMenuViewControllerDelegate> delegate;

@property (nonatomic, strong) PopMenuAppearance *appearance;

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) UIVisualEffectView *blurOverlayView;

// main root view that has shadows
@property (nonatomic, strong) UIView *containerView;

// Main content view.
@property (nonatomic, strong) UIView *contentView;

// View that contains all the actions
@property (nonatomic, strong) UIStackView *actionsView;

// The source View to be displayed from.
@property (nonatomic, weak) id sourceView;

- (UIView *)sourceViewAsUIView;

// The absolute source frame relative to the screen
@property (nonatomic, assign) CGRect absoluteSourceFrame;

// the calculated content frame
@property (nonatomic, assign) CGRect contentFrame;

- (CGRect)calculateContentFittingFrame;

#pragma mark - Configurations

// default is true
@property (nonatomic, assign) BOOL shouldDismissOnSelection;

// default is true
@property (nonatomic, assign) BOOL shouldEnablePanGesture;

// default is true for iPhone 7 and up
@property (nonatomic, assign) BOOL shouldEnableHaptics;

#pragma mark - Constraints

@property (nonatomic, strong) NSLayoutConstraint * contentLeftConstraint;
@property (nonatomic, strong) NSLayoutConstraint * contentTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint * contentWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint * contentHeightConstraint;

@end

NS_ASSUME_NONNULL_END
