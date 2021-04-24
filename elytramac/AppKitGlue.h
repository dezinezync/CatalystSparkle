//
//  AppKitGlue.h
//  elytramac
//
//  Created by Nikhil Nigade on 09/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Keychain.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppKitGlue : NSObject

+ (instancetype _Nonnull)shared;

@property (nonatomic, weak) NSUserDefaults *appUserDefaults;

@property (nonatomic, weak) id feedsManager;

- (void)openURL:(NSURL * _Nonnull)url inBackground:(BOOL)inBackground;

- (CGImageRef _Nullable)imageForFileType:(NSString * _Nonnull)fileType;

- (void)showPreferencesController;

- (void)deactivateAccount:(void(^)(BOOL success, NSError *error))completionBlock;

- (void)disableFullscreenButton:(id)window;

@end

NS_ASSUME_NONNULL_END
