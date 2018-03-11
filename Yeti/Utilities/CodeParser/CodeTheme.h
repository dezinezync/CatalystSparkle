//
//  CodeTheme.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeTheme : NSObject

@property (nonatomic, copy, readonly) NSString * _Nonnull themePath;

- (instancetype _Nonnull)initWithThemePath:(NSString * _Nonnull)path;

- (NSAttributedString * _Nonnull)applyStyle:(NSArray <NSString *> * _Nonnull)styleList toString:(NSString * _Nonnull)string;

@end
