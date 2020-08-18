//
//  NewFolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewFolderVC.h"
#import "Coordinator.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/AlertManager.h>

#import "FeedsManager.h"
#import "YTNavigationController.h"

#import "YetiConstants.h"

@interface NewFolderVC () {
    BOOL _isUpdating;
}

@property (nonatomic, weak, readwrite) Folder *folder;
@property (nonatomic, strong) UINotificationFeedbackGenerator *notificationGenerator;

@end

@implementation NewFolderVC

+ (UINavigationController *)instanceInNavController
{
    NewFolderVC *vc = [[NewFolderVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
#if !TARGET_OS_MACCATALYST
    nav.modalInPresentation = YES;
#endif
    return nav;
}

+ (UINavigationController *)instanceWithFolder:(Folder *)folder indexPath:(NSIndexPath *)indexPath
{
    NewFolderVC *vc = [[NewFolderVC alloc] initWithNibName:NSStringFromClass(NewFeedVC.class) bundle:nil];
    vc.folder = folder;
    vc.folderIndexPath = indexPath;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
#if !TARGET_OS_MACCATALYST
    nav.modalInPresentation = YES;
#endif
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
    
#if TARGET_OS_MACCATALYST
    self.navigationController.navigationBar.translucent = NO;
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self->_isUpdating) {
        return NO;
    }
    
    NSString *title = [textField text];
    
    if ([title isBlank]) {
        [AlertManager showGenericAlertWithTitle:@"Incomplete Title" message:@"Please provide a title for your new folder"];
        return NO;
    }
    
    if (title.length < 2 || title.length > 32) {
        [AlertManager showGenericAlertWithTitle:@"Title Length" message:@"Folder titles should be at least 3 characters and no longer than 32 characters."];
        return NO;
    }
    
    textField.enabled = NO;
    self.cancelButton.enabled = NO;
    
    weakify(self);
    
    self->_isUpdating = YES;
    
    SidebarVC *sidebarVC = self.mainCoordinator.sidebarVC;
    
    if (self.folder) {
        // editing the title
        [MyFeedsManager renameFolder:self.folder to:title success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                
                self->_isUpdating = NO;
                
                [self.mainCoordinator.sidebarVC setupData];
                
                self.cancelButton.enabled = YES;
                
                [sidebarVC setupData];
                
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [self didTapCancel];
                
            });

            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                strongify(self);
                
                self->_isUpdating = NO;
                
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
                [self.notificationGenerator prepare];
                
                textField.enabled = YES;
                self.cancelButton.enabled = YES;
                
            });
            
        }];
    }
    else {
        [MyFeedsManager addFolder:title success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                
                self->_isUpdating = NO;
                
                self.cancelButton.enabled = YES;
                
                [sidebarVC setupData];
                
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [self didTapCancel];
                
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:error.localizedDescription];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                
                self->_isUpdating = NO;
                
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
                [self.notificationGenerator prepare];
                
                textField.enabled = YES;
                self.cancelButton.enabled = YES;
                
            });
            
        }];
    }
    
    return YES;
}

#pragma mark - Getters

- (UINotificationFeedbackGenerator *)notificationGenerator {
    if (_notificationGenerator == nil) {
        _notificationGenerator = [[UINotificationFeedbackGenerator alloc] init];
        [_notificationGenerator prepare];
    }
    
    return _notificationGenerator;
}

@end
