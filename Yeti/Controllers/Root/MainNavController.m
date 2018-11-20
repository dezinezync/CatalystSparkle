//
//  MainNavController.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/11/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "MainNavController.h"
#import "FeedsVC.h"

@interface MainNavController ()

@end

@implementation MainNavController

- (instancetype)init {
    
    FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
    
    if (self = [super initWithRootViewController:vc]) {
        self.restorationIdentifier = @"mainNav";
//        self.restorationClass = [self class];
    }
    
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

#pragma mark - Restoration

//#define kControllerIdentifiers @"mainNavControllers"

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    MainNavController *nav = [[MainNavController alloc] init];

    return nav;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {

    DDLogDebug(@"Encoding restoration Nav: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];

}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding Restoration Nav: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
}

@end
