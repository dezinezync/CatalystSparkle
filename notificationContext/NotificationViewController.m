//
//  NotificationViewController.m
//  notificationContext
//
//  Created by Nikhil Nigade on 01/03/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "NotificationViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <UserNotificationsUI/UserNotificationsUI.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface NotificationViewController () <UNNotificationContentExtension>

@property (weak, nonatomic) IBOutlet UIImageView *coverImage;

@property (weak, nonatomic) IBOutlet UIImageView *favicon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIStackView *mainStack;
@property (weak, nonatomic) IBOutlet UIStackView *subStack;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverWidth;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverHeight;

@property (nonatomic, strong) NSURLCache *cache;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any required interface initialization here.
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.subStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverImage.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.favicon.layer.cornerRadius = 4.f;
    self.favicon.layer.cornerCurve = kCACornerCurveContinuous;
    self.favicon.layer.masksToBounds = YES;
    
//#ifdef DEBUG
//    self.coverImage.backgroundColor = UIColor.systemRedColor;
//#endif
    
}

- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    
    self.titleLabel.preferredMaxLayoutWidth = self.view.window.safeAreaLayoutGuide.layoutFrame.size.width - 24.f - 32.f - 8.f;
    self.subtitleLabel.preferredMaxLayoutWidth = self.titleLabel.preferredMaxLayoutWidth;
    
    [self.view layoutIfNeeded];
    
}

- (void)didReceiveNotification:(UNNotification *)notification {
    
    self.titleLabel.text = notification.request.content.title;
    self.subtitleLabel.text = notification.request.content.body;
    
    NSString *path = [notification.request.content.userInfo valueForKey:@"favicon"];
    
    if (path != nil) {
        
        [self setupFavicon:path];
        
    }
    
    path = [notification.request.content.userInfo valueForKey:@"coverImage"];
    
    if (path != nil) {
        [self setupCoverImage:path];
    }
    else {
        self.coverHeight.constant = 0.1f;

        [self.coverImage layoutIfNeeded];
//        self.coverImage.hidden = YES;
    }
    
    [self.titleLabel sizeToFit];
    [self.subtitleLabel sizeToFit];
    
}

- (void)setupFavicon:(NSString *)path {
    
    if (!path || [[path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return;
    }
    
    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat width = 32 * scale;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://images.weserv.nl/?url=%@&w=%@&dpr=%@&q=%@&we", path, @(width), @(scale), @(90)]];
    
    [self.favicon sd_setImageWithURL:url];
    
}

- (void)setupCoverImage:(NSString *)path {
    
    if (!path || [[path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return;
    }
    
    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat width = self.titleLabel.preferredMaxLayoutWidth + 32.f + 8.f;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://images.weserv.nl/?url=%@&w=%@&dpr=%@&q=%@&we", path, @(width), @(scale), @(90)]];
    
    [self.coverImage sd_setImageWithURL:url completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        
        self.coverWidth.constant = self.view.superview.bounds.size.width;
        self.coverHeight.constant = (image.size.height / image.size.width) * self.coverWidth.constant;

        [self.coverImage layoutIfNeeded];
        
    }];
    

}

@end
