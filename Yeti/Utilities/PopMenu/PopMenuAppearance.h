//
//  PopMenuAppearance.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PopMenuDirection) {
    PopMenuDirectionTop,
    PopMenuDirectionLeft,
    PopMenuDirectionRight,
    PopMenuDirectionBottom,
    PopMenuDirectionNone
};

@interface PopMenuPresentationStyle : NSObject

// The direction enum for the menu.
@property (nonatomic, assign) PopMenuDirection direction;

// custom offset coordinates
@property (nonatomic, assign) CGPoint offset;

- (instancetype)init;

- (instancetype)initNear:(CGPoint)point direction:(PopMenuDirection)direction;

@end

@interface PopMenuAppearance : NSObject

// the menu color
@property (nonatomic, strong) UIColor * popMenuColor;

// the background fade color
@property (nonatomic, strong) UIColor * popMenuBackgroundColor;

@property (nonatomic, strong) UIFont * popMenuFont;

// the text color
@property (nonatomic, strong) UIColor * popMenuTextColor;

@property (nonatomic, assign) CGFloat popMenuCornerRadius;

@property (nonatomic, assign) CGFloat popMenuActionHeight;

@property (nonatomic, assign) NSInteger popMenuActionCountForScrollable;

@property (nonatomic, assign) UIScrollViewIndicatorStyle popMenuScrollIndicatorStyle;

@property (nonatomic, assign) BOOL popMenuScrollIndicatorHidden;

@property (nonatomic, assign) UIStatusBarStyle popMenuStatusBarStyle;

@property (nonatomic, strong) PopMenuPresentationStyle *popMenuPresentationStyle;

@end

NS_ASSUME_NONNULL_END
