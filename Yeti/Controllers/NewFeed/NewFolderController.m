//
//  NewFolderController.m
//  Elytra
//
//  Created by Nikhil Nigade on 15/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "NewFolderController.h"
#import <DZKit/NSString+Extras.h>
#import "Elytra-Swift.h"

@interface NewFolderController () <UITextFieldDelegate>

@property (nonatomic, weak) UIAlertController *alertController;
@property (nonatomic, weak) UIAlertAction *confirmAction;
@property (nonatomic, weak) UITextField *textField;

@property (nonatomic, assign, readwrite) BOOL completed;

- (void)renameFolder:(NSString *)title;

@end

@implementation NewFolderController

- (instancetype)initWithFolder:(Folder *)exisitingFolder coordinator:(Coordinator *)coordinator completion:(folderControllerCompletion)completionBlock {
    
    if (self = [super init]) {
        
        self.exisitingFolder = exisitingFolder;
        self.coordinator = coordinator;
        self.completionHandler = completionBlock;
        
    }
    
    return self;
    
}

- (void)start {
    
    NSString *title = self.exisitingFolder != nil ? @"Edit Folder Title" : @"New Folder";
    
    weakify(self);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:@"" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.placeholder = title;
        textField.returnKeyType = UIReturnKeyDone;
        
        strongify(self);
        
        if (self.exisitingFolder != nil) {
            textField.text = ((Folder *)self.exisitingFolder).title;
        }
        
        self.textField = textField;
        self.textField.delegate = self;
        
    }];
    
    NSString *confirmTitle = self.exisitingFolder != nil ? @"Modify" : @"Confirm";
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

        strongify(self);
        
        [self textFieldDidEndEditing:self.textField];

    }];
    
    [alertController addAction:confirmAction];
    
    self.confirmAction = confirmAction;
    
    if (self.exisitingFolder == nil) {
        self.confirmAction.enabled = NO;
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        self.completed = YES;
        
        if (self.completionHandler) {
            self.completionHandler(self.exisitingFolder, NO, nil);
        }
        
    }];
    
    [alertController addAction:cancelAction];
    
    [self.coordinator.splitVC presentViewController:alertController animated:YES completion:^{
        
        [self.textField becomeFirstResponder];
        
    }];
    
    self.alertController = alertController;
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *textFieldText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([textFieldText isBlank] == YES) {
        self.confirmAction.enabled = NO;
    }
    else if ([textFieldText stringByStrippingWhitespace].length < 3) {
        self.confirmAction.enabled = NO;
    }
    else {
        self.confirmAction.enabled = YES;
    }
    
    return YES;
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (self.confirmAction.isEnabled == NO) {
        return;
    }
    
    self.confirmAction.enabled = NO;
    
    NSString *title = [textField.text stringByStrippingWhitespace];
    
    if (self.exisitingFolder != nil) {
        
        /**
         * If the titles match, return as true, but do nothing.
         */
        if ([((Folder *)self.exisitingFolder).title isEqualToString:title]) {
            
            if (self.completionHandler) {
                
                self.completionHandler(self.exisitingFolder, YES, nil);
                
            }
            
            self.completed = YES;
            
        }
        else {
            
            [self renameFolder:title];
            
        }
        
    }
    else {
        
        [self addFolder:title];
        
    }
    
}

#pragma mark - Networking

- (void)addFolder:(NSString *)title {
    
    [self.coordinator addFolderWithTitle:title completion:^(Folder * _Nullable folder, NSError * _Nullable error) {
        
        if (error != nil) {
            
            self.completed = YES;

            if (self.completionHandler) {

                self.completionHandler(nil, NO, error);

            }
            
            return;
            
        }
       
        self.completed = YES;

        if (self.completionHandler) {

            self.completionHandler(folder, YES, nil);

        }
        
    }];
    
}

- (void)renameFolder:(NSString *)title {
    
    [self.coordinator renameFolder:self.exisitingFolder title:title completion:^(BOOL completed, NSError * _Nullable error) {
       
        if (error != nil) {
            
            self.completed = YES;

            if (self.completionHandler) {

                self.completionHandler(self.exisitingFolder, NO, error);

            }
            
            return;
            
        }
        
        self.completed = YES;

        if (self.completionHandler) {

            self.completionHandler(self.exisitingFolder, YES, nil);

        }
        
    }];
    
}

@end
