//
//  LaunchVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "LaunchVC.h"
#import "TrialVC.h"
#import "Coordinator.h"

#import "Keychain.h"

#import "FeedsManager.h"
#import "DBManager.h"
#import <DZKit/AlertManager.h>

#import <AuthenticationServices/AuthenticationServices.h>

@interface LaunchVC () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;


@property (weak, nonatomic) ASAuthorizationAppleIDButton *signinButton;

- (void)didTapSignIn:(id)sender;

@end

@implementation LaunchVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.getStartedButton.hidden = YES;
    
    ASAuthorizationAppleIDButtonStyle style = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? ASAuthorizationAppleIDButtonStyleWhite : ASAuthorizationAppleIDButtonStyleBlack;
    
    ASAuthorizationAppleIDButton *button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeContinue style:style];
    
    [button addTarget:self action:@selector(didTapSignIn:) forControlEvents:UIControlEventTouchUpInside];
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:button];
    
    [NSLayoutConstraint activateConstraints:@[[button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                              [button.heightAnchor constraintEqualToConstant:44.f],
                                              [button.topAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:40.f],
                                              [button.widthAnchor constraintEqualToConstant:(320.f - (LayoutPadding * 2.f))]]];
    
    self.signinButton = button;
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    self.navigationController.navigationBarHidden = YES;
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    NSRange elytra = [attrs.string rangeOfString:@"Elytra"];
    UIColor *purple = [UIColor systemIndigoColor];
    
    if (purple == nil) {
        purple = [UIColor purpleColor];
    }
    
    [attrs setAttributes:@{
        NSFontAttributeName: baseFont ?: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
        NSForegroundColorAttributeName: UIColor.labelColor}
                   range:NSMakeRange(0, attrs.string.length)];
    
    [attrs setAttributes:@{NSForegroundColorAttributeName: purple} range:elytra];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = UIColor.secondaryLabelColor;
}

- (void)didTapSignIn:(id)sender {
    
    if (sender != self.signinButton) {
        return;
    }
    
#ifdef DEBUG
#if !TARGET_OS_MACCATALYST
    // 4800
    return [self processUUID:@"000768.e759fc828ab249ad98ceefc5f80279b3.1145"];
#endif
#endif
    
    self.signinButton.enabled = NO;
    
    ASAuthorizationAppleIDProvider *provider = [ASAuthorizationAppleIDProvider new];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[];
    
    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    controller.delegate = self;
    controller.presentationContextProvider = self;
    
    [controller performRequests];
    
}

- (void)processUUID:(NSString *)uuid {
    
    NSLog(@"Got %@", uuid);
    
    [MyFeedsManager getUserInformationFor:uuid success:^(User *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [MyDBManager setUser:responseObject];
        
        if ((MyFeedsManager.user.subscription == nil
            || MyFeedsManager.user.subscription.expiry == nil)
            && [Keychain boolFor:kHasShownOnboarding error:nil] == NO) {
            
            TrialVC *vc = [[TrialVC alloc] initWithNibName:NSStringFromClass(TrialVC.class) bundle:nil];
            
            [self showViewController:vc sender:self];
            
            return;
            
        }
        
        if (MyFeedsManager.user.subscription != nil && MyFeedsManager.user.subscription.hasExpired == NO) {
            
            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            
            [Keychain add:kHasShownOnboarding boolean:YES];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            
            return;
            
        }
        
        // existing User
        [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            BOOL expired = [MyFeedsManager.user subscription] != nil && [MyFeedsManager.user.subscription hasExpired] == YES;
            
            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                
                if (expired) {
                    
                    [self.mainCoordinator showSubscriptionsInterface];
                    
                }
                
            }];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            
        }];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if ([error.localizedDescription isEqualToString:@"User not found"]) {
            // create the new user.
            
            User *user = [User new];
            user.uuid = uuid;
            
            [MyFeedsManager createUser:uuid success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                NSLog(@"%@", responseObject);
                
                NSDictionary *userObj = [responseObject objectForKey:@"user"];
                NSNumber *userID = [userObj objectForKey:@"id"];
                
                user.userID = userID;
                
                [MyDBManager setUser:user];
                
                TrialVC *vc = [[TrialVC alloc] initWithNibName:NSStringFromClass(TrialVC.class) bundle:nil];
                
                [self showViewController:vc sender:self];
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                [AlertManager showGenericAlertWithTitle:@"Creating Account Failed" message:error.localizedDescription];
                
            }];
            
            return;
        }
       
        [AlertManager showGenericAlertWithTitle:@"Error Signing In" message:error.localizedDescription];
        
    }];
    
}

#pragma mark - <ASAuthorizationControllerDelegate>

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    
    self.signinButton.enabled = YES;
    
    if (error.code == 1001) {
        // cancel was tapped
    }
    else {
        NSLog(@"Authorization failed with error: %@", error.localizedDescription);
        [AlertManager showGenericAlertWithTitle:@"Log In Failed" message:error.localizedDescription];
    }
    
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization {
    
    self.signinButton.enabled = YES;
    
    NSLog(@"Authorized with credentials: %@", authorization);
    
    ASAuthorizationAppleIDCredential *credential = authorization.credential;
    
    if (credential) {
        
        NSString * userIdentifier = credential.user;
        
        [self processUUID:userIdentifier];
        
    }
    else {
        [AlertManager showGenericAlertWithTitle:@"Error Signing In" message:@"No Login information was received from Sign In with Apple."];
    }
    
}

#pragma mark - <ASAuthorizationControllerPresentationContextProviding>

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    
    return self.view.window;
    
}


@end
