//
//  AccountVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AccountVC.h"
#import "SettingsCell.h"
#import "FeedsManager.h"
#import "UIColor+HEX.h"

#import "LayoutConstants.h"
#import "YetiConstants.h"
#import "YetiThemeKit.h"
#import "AccountFooterView.h"
#import "DZWebViewController.h"
#import <DZKit/DZMessagingController.h>

#import "SplitVC.h"

#import "StoreVC.h"

@interface AccountVC () <UITextFieldDelegate, DZMessagingDelegate> {
    UITextField *_textField;
    UIAlertAction *_okayAction;
    BOOL _didTapDone;
}

@end

@implementation AccountVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Account";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    [self.tableView registerClass:AccountsCell.class forCellReuseIdentifier:kAccountsCell];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"deactivateCell"];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.tableView.backgroundColor = theme.tableColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 3;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return @"Subscription";
    
    return @"Acount ID";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"If you deactivate your account and wish to activate it again, please email us on support@elytra.app with the above UUID. You can long tap the UUID to copy it.";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = (indexPath.section == 0 && (indexPath.row == 1 || indexPath.row == 2)) ? @"deactivateCell" : kAccountsCell;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    if (!cell) {
        if ([identifier isEqualToString:kAccountsCell]) {
            cell = [[AccountsCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kAccountsCell];
        }
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"deactivateCell"];
        }
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.textLabel.textColor = theme.titleColor;
    cell.detailTextLabel.textColor = theme.captionColor;
    
    if (@available(iOS 13, *)) {
        cell.backgroundColor = theme.backgroundColor;
    }
    else {
        cell.backgroundColor = theme.cellColor;
    }
    
    if (cell.selectedBackgroundView == nil) {
        cell.selectedBackgroundView = [UIView new];
    }
    
    cell.selectedBackgroundView.backgroundColor = [[theme tintColor] colorWithAlphaComponent:0.3f];
    
    switch (indexPath.section) {
        case 0:
            {
                switch (indexPath.row) {
                    case 0:
                    {
                        cell.textLabel.text = @"Acc. ID";
                        cell.textLabel.accessibilityValue = @"Account Label";
                        
                        cell.detailTextLabel.text = MyFeedsManager.userIDManager.UUID.UUIDString;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        cell.separatorInset = UIEdgeInsetsZero;
                    }
                        break;
                    case 1:
                    {
                        cell.textLabel.text = @"Change Account ID";
                        cell.textLabel.textColor = theme.tintColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.separatorInset = UIEdgeInsetsZero;
                    }
                        break;
                    default:
                        cell.textLabel.text = @"Deactivate Account";
                        cell.textLabel.textColor = UIColor.redColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        cell.separatorInset = UIEdgeInsetsZero;
                        break;
                }
            }
            break;
            
        default:
        {
            cell.textLabel.text = @"Your Subscription";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 0;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    return [NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0);
}

- (void)tableView:(UITableView *)tableView performAction:(nonnull SEL)action forRowAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"] && (indexPath.row == 0 && indexPath.section == 0)) {
        
        [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUID.UUIDString];
        
    }
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
   if (indexPath.section == 0) {
        
        if (indexPath.row == 1) {
            [self showReplaceIDController];
        }
        
        if (indexPath.row == 2) {
            UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Deactivate your Account?" message:@"Please ensure you have cancelled your Elytra Pro subscription before continuing." preferredStyle:UIAlertControllerStyleAlert];
            
            [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            
            weakify(self);
            
            [avc addAction:[UIAlertAction actionWithTitle:@"Deactivate" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                
                asyncMain(^{
                    strongify(self);
                    [self showInterfaceToSendDeactivationEmail];
                });
                
            }]];
            
            [self presentViewController:avc animated:YES completion:nil];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
   else {
       
       StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
//       vc.inStack = YES;
       [self showViewController:vc sender:self];
       
   }
    
}

#pragma mark - Getters

#pragma mark - Actions

- (void)showInterfaceToSendDeactivationEmail {
    NSString *formatted = formattedString(@"Deactivate Account: %@<br />User Conset: Yes<br />User confirmed subscription cancelled: Yes", MyFeedsManager.userIDManager.UUIDString);
    
    DZMessagingController.shared.delegate = self;
    
    [DZMessagingController presentEmailWithBody:formatted subject:@"Deactivate Elytra Account" recipients:@[@"support@elytra.app"] fromController:self];
}

- (void)showReplaceIDController {
    
    if (self.navigationController.presentedViewController)
        return;
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Replace Account ID" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    weakify(self);
    
    UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        NSString *text = [self->_textField text];
        
        [MyFeedsManager getUserInformationFor:text success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            NSDictionary *user = [responseObject valueForKey:@"user"];
            
            if (!user) {
                [AlertManager showGenericAlertWithTitle:@"No User" message:@"No user was found with this UUID."];
                return;
            }
            
            NSString *UUID = [user valueForKey:@"uuid"];
            NSNumber *userID = [user valueForKey:@"id"];
            
//            if ([MyFeedsManager.userIDManager.userID isEqualToNumber:userID]) {
//                return;
//            }
            
            MyFeedsManager.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:UUID];
            MyFeedsManager.userIDManager.userID = userID;
            MyFeedsManager.userID = userID;
            
            asyncMain(^{
                [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            });
            
            [AlertManager showGenericAlertWithTitle:@"Updated" message:@"Your account was successfully updated to use the new ID."];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Fetch Error" message:error.localizedDescription];
            
        }];
        
        self->_okayAction = nil;
        self->_textField = nil;
        
    }];
    
    okay.enabled =  NO;
    
    [alertVC addAction:okay];
    _okayAction = okay;
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        self->_okayAction = nil;
        self->_textField = nil;
        
    }]];
    
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       
        textField.placeholder = @"Account ID";
        textField.delegate = self;
        
        strongify(self);
        
        self->_textField = textField;
        
    }];
    
    [self presentViewController:alertVC animated:YES completion:nil];
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    _okayAction.enabled = text.length == 36;
    
    return YES;
}

#pragma mark - <DZMessagingDelegate>

- (void)userDidSendEmail {
    
    [DZMessagingController shared].delegate = nil;
    
    [MyFeedsManager resetAccount];
    
    UINavigationController *nav = self.navigationController;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [nav popToRootViewControllerAnimated:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [nav dismissViewControllerAnimated:YES completion:^{
                
                SplitVC *v = (SplitVC *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
                [v userNotFound];
                
            }];
        });
    });
    
}

- (void)emailWasCancelledOrFailedToSend {
    [DZMessagingController shared].delegate = nil;
}

@end
