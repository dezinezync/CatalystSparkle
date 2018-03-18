//
//  SettingsChanges.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#ifndef SettingsChanges_h
#define SettingsChanges_h

@protocol SettingsChanges <NSObject>

- (void)didChangeSettings;

@end

@protocol SettingsNotifier <NSObject>

@property (nonatomic, assign) id <SettingsChanges> settingsDelegate;

@end

#endif /* SettingsChanges_h */
