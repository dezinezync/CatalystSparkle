//
//  SceneDelegate.h
//  AuthTest
//
//  Created by Nikhil Nigade on 23/07/20.
//

#import <UIKit/UIKit.h>
#import "Coordinator.h"

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate> {
    UIImageSymbolConfiguration * _Nullable _toolbarSymbolConfiguration;
}

@property (strong, nonatomic) UIWindow * _Nonnull window;

@property (strong, nonatomic) MainCoordinator * _Nonnull coordinator;

#if TARGET_OS_MACCATALYST

@property (nonatomic, weak) NSToolbar *toolbar;

@property (nonatomic, weak) NSMenuToolbarItem *sortingItem;

@property (nonatomic) UIImageSymbolConfiguration *toolbarSymbolConfiguration;

#endif

@end

