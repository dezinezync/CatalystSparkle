//
//  LaunchVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "LaunchVC.h"
#import "TrialVC.h"
#import "IdentityVC.h"

#import "YetiThemeKit.h"

#import "FeedsManager.h"
#import <DZKit/AlertManager.h>

#import <AuthenticationServices/AuthenticationServices.h>

@interface LaunchVC () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;


@property (weak, nonatomic) ASAuthorizationAppleIDButton *signinButton API_AVAILABLE(ios(13.0));

- (void)didTapSignIn:(id)sender API_AVAILABLE(ios(13.0));

@end

@implementation LaunchVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.layer.cornerRadius = 20.f;

    if (@available(iOS 13, *)) {
        self.view.layer.cornerCurve = kCACornerCurveContinuous;
        self.getStartedButton.hidden = YES;
        
        ASAuthorizationAppleIDButtonStyle style = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? ASAuthorizationAppleIDButtonStyleWhite : ASAuthorizationAppleIDButtonStyleBlack;
        
        ASAuthorizationAppleIDButton *button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeContinue style:style];
        
        [button addTarget:self action:@selector(didTapSignIn:) forControlEvents:UIControlEventTouchUpInside];
        
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addSubview:button];
        
        [NSLayoutConstraint activateConstraints:@[[button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
                                                  [button.heightAnchor constraintEqualToConstant:44.f],
                                                  [button.topAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:40.f],
                                                  [button.widthAnchor constraintLessThanOrEqualToConstant:320.f]]];
        
        self.signinButton = button;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.view.backgroundColor = theme.backgroundColor;
    
    self.navigationController.navigationBarHidden = YES;
    
    NSMutableAttributedString *attrs = self.titleLabel.attributedText.mutableCopy;
    
    UIFont *bigFont = [UIFont systemFontOfSize:40 weight:UIFontWeightHeavy];
    UIFontMetrics *baseMetrics = [[UIFontMetrics alloc] initForTextStyle:UIFontTextStyleTitle1];
    
    UIFont *baseFont = [baseMetrics scaledFontForFont:bigFont];
    
    self.titleLabel.font = baseFont;
    
    NSRange elytra = [attrs.string rangeOfString:@"Elytra"];
    UIColor *purple = [UIColor colorWithDisplayP3Red:42.f/255.f green:0.f blue:1.f alpha:1.f];
    
    if (@available(iOS 13, *)) {
        purple = [UIColor systemIndigoColor];
    }
    
    [attrs setAttributes:@{NSFontAttributeName: baseFont, NSForegroundColorAttributeName: theme.titleColor} range:NSMakeRange(0, attrs.string.length)];
    [attrs setAttributes:@{NSForegroundColorAttributeName: purple} range:elytra];
    
    self.titleLabel.attributedText = attrs;
    self.subtitleLabel.textColor = theme.subtitleColor;
}

- (IBAction)didTapButton:(id)sender {
    
    IdentityVC *vc = [[IdentityVC alloc] initWithNibName:NSStringFromClass(IdentityVC.class) bundle:nil];
    
    [self showViewController:vc sender:self];
    
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
    
    self.signinButton.enabled = YES;
    
    NSLog(@"Authorized with credentials: %@", authorization);
    
    ASAuthorizationAppleIDCredential *credential = authorization.credential;
    
    if (credential) {
        NSString * userIdentifier = credential.user;
        
        NSLog(@"Got %@", userIdentifier);
        
        [MyFeedsManager getUserInformationFor:userIdentifier success:^(NSDictionary *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
            
            TrialVC *vc = [[TrialVC alloc] initWithNibName:NSStringFromClass(TrialVC.class) bundle:nil];
            
            [self showViewController:vc sender:self];
            
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
