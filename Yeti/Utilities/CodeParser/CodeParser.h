//
//  CodeParser.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import "CodeTheme.h"

@class CodeParser;

extern CodeParser * _Nonnull MyCodeParser;

@interface CodeParser : NSObject

+ (instancetype _Nonnull)sharedCodeParser;

- (NSAttributedString * _Nullable)parse:(NSString * _Nonnull)code language:(NSString * _Nonnull)language;
- (NSAttributedString * _Nullable)parse:(NSString * _Nonnull)code;

- (void)loadTheme:(NSString * _Nonnull)name;

@property (nonatomic, strong, readonly) CodeTheme * _Nullable theme;

@end
