//
//  AppDelegate.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZAppdelegate/DZAppdelegate.h>

@class AppDelegate;

extern AppDelegate * MyAppDelegate;

@interface AppDelegate : DZAppDelegate

@property (nonatomic, weak) UIAlertController *addFeedDialog;

@end

