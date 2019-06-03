//
//  PopMenuDefaultAction.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define kPopMenuDefaultTextLeftPadding 24.f
#define kPopMenuDefaultIconLeftPadding 16.f

typedef void (^PopMenuActionHandler)(id action);

@protocol PopMenuAction <NSObject>

@property (nonatomic, copy) NSString * title;

@property (nonatomic, strong) UIImage * image;

// container view of this action
@property (nonatomic, strong) UIView * view;

@property (nonatomic, strong) UIColor * color;

@property (nonatomic, copy) PopMenuActionHandler didSelect;

@property (nonatomic, assign) CGFloat textLeftPadding;

@property (nonatomic, assign) CGFloat iconLeftPadding;

// icon sizing
@property (nonatomic, assign) CGFloat iconWidthHeight;

// color for the label and icon
@property (nonatomic, strong) UIColor * tintColor;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) CGFloat cornerRadius;

// is the view highlighted by gesture
@property (nonatomic, assign, getter=isHighlighted) BOOL highlighted;

- (void)renderActionView;

@optional

- (void)actionSelected:(BOOL)animated;

@end

@interface PopMenuDefaultAction : NSObject <PopMenuAction>

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image color:(UIColor *)color didSelect:(PopMenuActionHandler)didSelect;

@property (nonatomic, copy) NSString * title;

@property (nonatomic, strong) UIImage * image;

// container view of this action
@property (nonatomic, strong) UIView * view;

@property (nonatomic, strong) UIColor * color;

@property (nonatomic, copy) PopMenuActionHandler didSelect;

@property (nonatomic, assign) CGFloat textLeftPadding;

@property (nonatomic, assign) CGFloat iconLeftPadding;

// icon sizing
@property (nonatomic, assign) CGFloat iconWidthHeight;

// color for the label and icon
@property (nonatomic, strong) UIColor * tintColor;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, assign) CGFloat cornerRadius;

// is the view highlighted by gesture
@property (nonatomic, assign, getter=isHighlighted) BOOL highlighted;

- (void)renderActionView;

- (void)actionSelected:(BOOL)animated;

+ (UIColor *)blackOrWhiteContrastingColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
