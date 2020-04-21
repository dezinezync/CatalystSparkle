//
//  ImageLoadingVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZTextKit/YetiConstants.h>
#import "SettingsChanges.h"

@interface ImageLoadingVC : UITableViewController <SettingsNotifier>

@property (nonatomic, weak) id<SettingsChanges> settingsDelegate;

@end
