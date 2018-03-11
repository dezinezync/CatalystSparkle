//
//  CodeParser.h
//  Yeti
//
//  Created by Nikhil Nigade on 11/1/16.
//  Copyright © 2016 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class CodeParser;

extern CodeParser * _Nonnull MyCodeParser;

@interface CodeParser : NSObject

- (NSAttributedString * _Nullable)parse:(NSString * _Nonnull)code language:(NSString * _Nonnull)language;
- (NSAttributedString * _Nullable)parse:(NSString * _Nonnull)code;

@end
