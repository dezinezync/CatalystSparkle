//
//  NewFolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFolderVC.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/AlertManager.h>

#import "FeedsManager.h"

@interface NewFolderVC ()

@property (nonatomic, weak, readwrite) Folder *folder;

@end

@implementation NewFolderVC

+ (UINavigationController *)instanceInNavController
{
    NewFolderVC *vc = [[NewFolderVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = vc.newVCTD;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    
    return nav;
}

+ (UINavigationController *)instanceWithFolder:(Folder *)folder
{
    NewFolderVC *vc = [[NewFolderVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    vc.folder = folder;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = vc.newVCTD;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    
    return nav;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"New Folder";
    
    self.input.placeholder = @"Folder Name (3-32 chars)";
    self.input.keyboardType = UIKeyboardTypeDefault;
    
    if (self.folder) {
        // editing
        self.title = @"Edit Folder";
        self.input.text = self.folder.title;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *title = [textField text];
    
    if ([title isBlank]) {
        [AlertManager showGenericAlertWithTitle:@"Incomplete title" message:@"Please provide a title for your new folder"];
        return NO;
    }
    
    if (title.length < 3 || title.length > 32) {
        [AlertManager showGenericAlertWithTitle:@"Title length" message:@"Folder titles should be more than 3 letters and no longer than 32 characters."];
        return NO;
    }
    
    textField.enabled = NO;
    self.cancelButton.enabled = NO;
    
    weakify(self);
    
    if (self.folder) {
        // editing the title
        [MyFeedsManager renameFolder:self.folder.folderID to:title success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            self.cancelButton.enabled = YES;
            
            [self didTapCancel];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
            
            strongify(self);
            
            textField.enabled = YES;
            self.cancelButton.enabled = YES;
            
        }];
    }
    else {
        [MyFeedsManager addFolder:title success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            self.cancelButton.enabled = YES;
            
            [self didTapCancel];
            
            [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : MyFeedsManager.feeds, @"folders": MyFeedsManager.folders}];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
            
            strongify(self);
            
            textField.enabled = YES;
            self.cancelButton.enabled = YES;
            
        }];
    }
    
    return YES;
}

@end
