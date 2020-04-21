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
#import <DZTextKit/UIColor+HEX.h>

#import <DZTextKit/LayoutConstants.h>
#import <DZTextKit/YetiConstants.h>
#import "YetiThemeKit.h"
#import "AccountFooterView.h"
#import "DZWebViewController.h"
#import <DZKit/DZMessagingController.h>

#import "SplitVC.h"

#import "StoreVC.h"
#import <DZTextKit/PaddedLabel.h>

#import <AuthenticationServices/AuthenticationServices.h>
#import <DZAppdelegate/UIApplication+KeyWindow.h>

@interface AccountVC () <UITextFieldDelegate, DZMessagingDelegate, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding> {
    UITextField *_textField;
    UIAlertAction *_okayAction;
    BOOL _didTapDone;
}

@property (nonatomic, strong) UILabel *footerSizingLabel;
@property (weak, nonatomic) ASAuthorizationAppleIDButton *signinButton API_AVAILABLE(ios(13.0));

- (void)didTapSignIn:(id)sender API_AVAILABLE(ios(13.0));

@end

@implementation AccountVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Account";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    self.tableView.estimatedRowHeight = 44.f + (LayoutPadding * 2.f);
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.tableView.estimatedSectionFooterHeight = 80.f;
    self.tableView.sectionFooterHeight = UITableViewAutomaticDimension;
    
    [self.tableView registerClass:AccountsCell.class forCellReuseIdentifier:kAccountsCell];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"deactivateCell"];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.tableView.backgroundColor = theme.tableColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    
    if (section == 0) {
        return @"If you deactivate your account and wish to activate it again, please email me on support@elytra.app with the above UUID. You can long tap the UUID to copy it.";
    }
    else if (section == 2) {
        return @"Connect your Apple ID to your Elytra account. This will enable you to sign in on other platforms as well. Elytra from v1.6 will only use the Apple ID mechanism.";
    }
    else {
        return nil;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"\\d{6}\\.[a-zA-Z0-9]{32}\\.\\d{4}" options:kNilOptions error:nil];
    
    NSString *UUID = MyFeedsManager.userIDManager.UUIDString;
    
    if (exp != nil && [exp numberOfMatchesInString:UUID options:kNilOptions range:NSMakeRange(0, UUID.length)] > 0) {
        return 2;
    }
    
    return 3;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Subscription";
    }
    else if (section == 2) {
        return nil;
    }
    
    return @"Account ID";
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
    
    cell.backgroundColor = theme.backgroundColor;
    
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
                        cell.textLabel.text = nil;
                        cell.textLabel.accessibilityValue = @"Account Label";
                        
                        cell.detailTextLabel.text = MyFeedsManager.userIDManager.UUIDString;
                        cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    }
                        break;
//                    case 1:
//                    {
//                        cell.textLabel.text = @"Change Account ID";
//                        cell.textLabel.textColor = theme.tintColor;
//                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
//                    }
//                        break;
                    default:
                        cell.textLabel.text = @"Deactivate Account";
                        cell.textLabel.textColor = UIColor.redColor;
                        cell.textLabel.textAlignment = NSTextAlignmentCenter;
                        break;
                }
            }
            break;
        case 2:
        {
            
            cell.textLabel.text = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.backgroundColor = self.tableView.backgroundColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.clipsToBounds = NO;

            [cell.contentView setContentCompressionResistancePriority:999 forAxis:UILayoutConstraintAxisVertical];
            
            ASAuthorizationAppleIDButtonStyle style = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? ASAuthorizationAppleIDButtonStyleWhite : ASAuthorizationAppleIDButtonStyleBlack;
            
            ASAuthorizationAppleIDButton *button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeContinue style:style];
            
            [button addTarget:self action:@selector(didTapSignIn:) forControlEvents:UIControlEventTouchUpInside];
            
            button.translatesAutoresizingMaskIntoConstraints = NO;
            
            [cell.contentView addSubview:button];
            
            [NSLayoutConstraint activateConstraints:@[[button.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor],
                                                      [cell.contentView.heightAnchor constraintEqualToAnchor:button.heightAnchor multiplier:1.f]]];
            
            self.signinButton = button;
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

-(UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    
    UIContextMenuConfiguration *config = nil;
    
    if (indexPath.row == 0 && indexPath.section == 0) {
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:@"copyUUID" previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
           
            UIAction *copyItem = [UIAction actionWithTitle:@"Copy Account ID" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
               
                [[UIPasteboard generalPasteboard] setString:MyFeedsManager.userIDManager.UUIDString];
                
            }];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Account ID" children:@[copyItem]];
            
            return menu;
            
        }];

    }
    
    return config;
    
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
   if (indexPath.section == 0) {
        
//        if (indexPath.row == 1) {
//            [self showReplaceIDController];
//        }
        
        if (indexPath.row == 1) {
            UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Deactivate your Account?" message:@"If you have remaining days on your Pro Subscription, no refund can be issued for the same." preferredStyle:UIAlertControllerStyleAlert];
            
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
   else if (indexPath.section == 1) {
       
       StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
//       vc.inStack = YES;
       [self showViewController:vc sender:self];
       
   }
    
}

#pragma mark - Getters

//- (UILabel *)footerSizingLabel {
//    
//    if (!_footerSizingLabel) {
//        UILabel *label = [UILabel new];
//        label.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 0.f);
//        label.font = TypeFactory.shared.footnoteFont;
//        label.numberOfLines = 0;
//        
//        _footerSizingLabel = label;
//        
//    }
//    
//    return _footerSizingLabel;
//    
//}

#pragma mark - Actions

- (void)deactivateFromAPI {
    
    [MyFeedsManager deactivateAccountWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
#ifndef DEBUG
        [self userDidSendEmail];
#endif
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Error Deactivating Account" message:error.localizedDescription];
        
    }];
    
}

- (void)showInterfaceToSendDeactivationEmail {
    
    [self deactivateFromAPI];
    return;
    
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

- (void)didTapSignIn:(id)sender {
    
    if (sender != self.signinButton) {
        return;
    }
    
    self.signinButton.enabled = NO;
    
    ASAuthorizationAppleIDProvider *provider = [ASAuthorizationAppleIDProvider new];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[];
    
    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    controller.delegate = self;
    controller.presentationContextProvider = self;
    
    [controller performRequests];
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    _okayAction.enabled = text.length == 36;
    
    return YES;
}

#pragma mark - <DZMessagingDelegate>

- (void)userDidSendEmail {
    
//    [DZMessagingController shared].delegate = nil;
    
    [MyFeedsManager resetAccount];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *nav = self.navigationController;
        
        [nav popToRootViewControllerAnimated:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [nav dismissViewControllerAnimated:YES completion:^{
                
                SplitVC *v = (SplitVC *)[UIApplication.keyWindow rootViewController];
                [v userNotFound];
                
            }];
        });
    });
    
}

- (void)emailWasCancelledOrFailedToSend {
    [DZMessagingController shared].delegate = nil;
}


#pragma mark - <ASAuthorizationControllerDelegate>

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
    
    self.signinButton.enabled = YES;
    
    if (error.code == 1001) {
        // cancel was tapped
    }
    else {
        NSLog(@"Authorization failed with error: %@", error.localizedDescription);
    }
    
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization  API_AVAILABLE(ios(13.0)) {
    
    NSLog(@"Authorized with credentials: %@", authorization);
    
    ASAuthorizationAppleIDCredential *credential = authorization.credential;
    
    if (credential) {
        NSString * userIdentifier = credential.user;
        
        NSLog(@"Got %@", userIdentifier);
        
        [MyFeedsManager signInWithApple:userIdentifier success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [self.tableView reloadData];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"Error Signing In" message:error.localizedDescription];
            
        }];
        
    }
    
}

#pragma mark - <ASAuthorizationControllerPresentationContextProviding>

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller  API_AVAILABLE(ios(13.0)) {
    
    return self.view.window;
    
}

@end
