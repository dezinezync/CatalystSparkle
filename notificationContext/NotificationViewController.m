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

@interface NotificationViewController () <UNNotificationContentExtension>

@property (weak, nonatomic) IBOutlet UIImageView *favicon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (weak, nonatomic) IBOutlet UIStackView *mainStack;
@property (weak, nonatomic) IBOutlet UIStackView *subStack;

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
    
    self.favicon.layer.cornerRadius = 4.f;
    self.favicon.layer.cornerCurve = kCACornerCurveContinuous;
    self.favicon.layer.masksToBounds = YES;
    
    self.view.backgroundColor = UIColor.systemBackgroundColor;
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
        
        CGFloat scale = UIScreen.mainScreen.scale;
        CGFloat width = 32 * scale;
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://images.weserv.nl/?url=%@&w=%@&dpr=%@&q=%@&we", path, @(width), @(scale), @(90)]];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSData *data = [NSData dataWithContentsOfURL:url];
            
            if (data != nil) {
            
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    UIImage *image = [UIImage imageWithData:data];
                    
                    if (image != nil) {
                        self.favicon.image = image;
                    }
                    
                });
                
            }
            
        });
        
    }
    
    [self.titleLabel sizeToFit];
    [self.subtitleLabel sizeToFit];
    
}

@end
