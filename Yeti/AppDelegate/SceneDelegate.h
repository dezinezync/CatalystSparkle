//
//  SceneDelegate.h
//  AuthTest
//
//  Created by Nikhil Nigade on 23/07/20.
//

#import <UIKit/UIKit.h>

@class Coordinator;

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate> {
    UIImageSymbolConfiguration * _Nullable _toolbarSymbolConfiguration;
}

@property (strong, nonatomic) UIWindow * _Nonnull window;

@property (strong, nonatomic) Coordinator * _Nonnull coordinator;

#if TARGET_OS_MACCATALYST

@property (nonatomic, weak) NSToolbar * _Nullable toolbar;

@property (nonatomic, weak) NSMenuToolbarItem * _Nullable sortingItem;

@property (nonatomic) UIImageSymbolConfiguration * _Nullable toolbarSymbolConfiguration;

#endif

@end

