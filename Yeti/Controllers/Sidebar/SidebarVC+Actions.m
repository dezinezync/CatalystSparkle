//
//  SidebarVC+Actions.m
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+SearchResults.h"
#import "AddFeedVC.h"
#import "NewFolderVC.h"
#import "SettingsVC.h"

#import "Coordinator.h"

@implementation SidebarVC (Actions)

- (void)didTapAdd:(UIBarButtonItem *)add
{
    
    UINavigationController *nav = [AddFeedVC instanceInNavController];
    
    nav.viewControllers.firstObject.mainCoordinator = self.mainCoordinator;
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (void)didTapAddFolder:(UIBarButtonItem *)add {
    
    UINavigationController *nav = [NewFolderVC instanceInNavController];
    
    nav.viewControllers.firstObject.mainCoordinator = self.mainCoordinator;
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (void)didTapSettings
{
    SettingsVC *settingsVC = [[SettingsVC alloc] initWithNibName:NSStringFromClass(SettingsVC.class) bundle:nil];
    
    settingsVC.mainCoordinator = self.mainCoordinator;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    [self.splitViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)didTapRecommendations:(UIBarButtonItem *)sender
{
    
    [self.mainCoordinator showRecommendations];
    
}

@end
