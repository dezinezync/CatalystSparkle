//
//  AppKitGlue.h
//  elytramac
//
//  Created by Nikhil Nigade on 09/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppKitGlue : NSObject

+ (instancetype _Nonnull)shared;

- (void)ct_showAlertWithTitle:(NSString * _Nonnull)title message:(NSString * _Nullable)message cancelButtonTitle:(NSString * _Nullable)cancelButtonTitle otherButtonTitle:(NSString * _Nullable)otherButtonTitle completionHandler:(void(^ _Nullable)(NSString *buttonTitle))completionHandler;

@end

NS_ASSUME_NONNULL_END
