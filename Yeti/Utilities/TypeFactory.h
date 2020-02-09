//
//  TypeFactory.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName UserUpdatedPreferredFontMetrics;

@interface TypeFactory : NSObject

+ (instancetype)shared;

@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIFont *caption1Font;
@property (nonatomic, strong) UIFont *caption2Font;
@property (nonatomic, strong) UIFont *subtitleFont;
@property (nonatomic, strong) UIFont *footnoteFont;

@property (nonatomic, strong) UIFont *bodyFont;
@property (nonatomic, strong) UIFont *boldBodyFont;
@property (nonatomic, strong) UIFont *italicBodyFont;
@property (nonatomic, strong) UIFont *boldItalicBodyFont;

@property (nonatomic, strong) UIFont *codeFont;
@property (nonatomic, strong) UIFont *boldCodeFont;
@property (nonatomic, strong) UIFont *italicCodeFont;

@end

NS_ASSUME_NONNULL_END
