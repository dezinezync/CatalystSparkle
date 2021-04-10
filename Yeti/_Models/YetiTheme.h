//
//  YetiTheme.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YetiTheme : NSObject

@property (nonatomic, copy) UIColor *cellColor;

@property (nonatomic, copy) UIColor *unreadBadgeColor;

@property (nonatomic, copy) UIColor *unreadTextColor;

@property (nonatomic, copy) UIColor *articlesBarColor;

@property (nonatomic, copy) UIColor *subbarColor;

@property (nonatomic, copy) UIColor *focusColor;

@property (nonatomic, copy) UIColor *articleBackgroundColor;

@property (nonatomic, copy) UIColor *opmlViewColor;

@property (nonatomic, copy) NSNumber *tintColorIndex;

#pragma mark - 1.3
@property (nonatomic, copy) UIColor *menuColor;

@property (nonatomic, copy) UIColor *menuTextColor;

#pragma mark - 1.4

@property (nonatomic, copy) UIColor *paragraphColor;

#pragma mark - 2.3-macOS

@property (nonatomic, copy) UIColor *backgroundColor;

@property (nonatomic, copy) UIColor *borderColor;

@property (nonatomic, copy) UIColor *tableColor;

@end
