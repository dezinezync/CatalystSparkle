//
//  AppKitGlue.h
//  elytramac
//
//  Created by Nikhil Nigade on 09/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_MACCATALYST
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppKitGlue : NSObject

+ (instancetype _Nonnull)shared;

- (CGColorRef _Nullable)CTColorForName:(NSString * _Nonnull)name;

- (void)ct_showAlertWithTitle:(NSString * _Nonnull)title message:(NSString * _Nullable)message cancelButtonTitle:(NSString * _Nullable)cancelButtonTitle otherButtonTitle:(NSString * _Nullable)otherButtonTitle completionHandler:(void(^ _Nullable)(NSString *buttonTitle))completionHandler;

- (void)openURL:(NSURL * _Nonnull)url inBackground:(BOOL)inBackground;

- (CGImageRef _Nullable)imageForFileType:(NSString * _Nonnull)fileType;

@end

NS_ASSUME_NONNULL_END
#endif
