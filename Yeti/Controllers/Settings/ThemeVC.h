//
//  ThemeVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 30/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsChanges.h"

#import "YetiConstants.h"

@interface ThemeVC : UITableViewController <SettingsNotifier>

+ (NSArray <ArticleLayoutFont> *)fonts;

+ (NSDictionary <ArticleLayoutFont, NSString *> *)fontNamesMap;

@property (nonatomic, weak) id <SettingsChanges> settingsDelegate;

@end
