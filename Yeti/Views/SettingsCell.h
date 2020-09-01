//
//  SettingsCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsBaseCell : UITableViewCell

@end

extern NSString *const kSettingsCell;

@interface SettingsCell : SettingsBaseCell

@end

extern NSString *const kAccountsCell;

@interface AccountsCell : SettingsCell

@end

extern NSString *const kExternalAppsCell;

@interface ExternalAppsCell : SettingsBaseCell

@end

extern NSString *const kDeactivateCell;

@interface DeactivateCell : SettingsBaseCell

@end

extern NSString *const kStoreCell;

@interface StoreCell : SettingsBaseCell

@end
