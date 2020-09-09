//
//  SceneDelegate.h
//  AuthTest
//
//  Created by Nikhil Nigade on 23/07/20.
//

#import <UIKit/UIKit.h>
#import "Coordinator.h"

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow * window;

@property (strong, nonatomic) MainCoordinator *coordinator;

- (void)loadCodeTheme;

#if TARGET_OS_MACCATALYST

@property (nonatomic, weak) NSToolbar *toolbar;

@property (nonatomic, weak) NSMenuToolbarItem *sortingItem;

#endif

@end

