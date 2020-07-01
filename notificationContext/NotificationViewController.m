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
        self.coverImage.hidden = YES;
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
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    
    __block NSCachedURLResponse *cached = [self.cache cachedResponseForRequest:request];
    
    if (cached != nil) {
        
        UIImage *image = [UIImage imageWithData:cached.data];
        
        self.favicon.image = image;
        
        return;
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
        [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error != nil) {
                NSLog(@"Error loading %@: %@", url, error.localizedDescription);
                return;
            }
            
            if (data == nil) {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                UIImage *image = [UIImage imageWithData:data];
                
                if (image == nil) {
                    return;
                }
                
                cached = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
                
                [self.cache storeCachedResponse:cached forRequest:request];
                
                self.favicon.image = image;
                
            });
            
        }] resume];
        
    });
    
}

- (void)setupCoverImage:(NSString *)path {
    
    if (!path || [[path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return;
    }
    
    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat width = self.titleLabel.preferredMaxLayoutWidth + 32.f + 8.f;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://images.weserv.nl/?url=%@&w=%@&dpr=%@&q=%@&we", path, @(width), @(scale), @(90)]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    
    __block NSCachedURLResponse *cached = [self.cache cachedResponseForRequest:request];
    
    if (cached != nil) {
        
        UIImage *image = [UIImage imageWithData:cached.data];
        
        [self _setCoverImage:image];
        
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error != nil) {
                NSLog(@"Error loading %@: %@", url, error.localizedDescription);
                return;
            }
            
            if (data == nil) {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                UIImage *image = [UIImage imageWithData:data];
                
                if (image == nil) {
                    return;
                }
                
                cached = [[NSCachedURLResponse alloc] initWithResponse:response data:data];
                
                [self.cache storeCachedResponse:cached forRequest:request];
                
                [self _setCoverImage:image];
                
            });
            
        }] resume];
        
    });
    
}

- (void)_setCoverImage:(UIImage *)image {
    
    self.coverImage.backgroundColor = UIColor.clearColor;
    
    self.coverImage.image = image;
    
    if (image == nil) {
        return;
    }
    
    self.coverWidth.constant = self.view.superview.bounds.size.width;
    self.coverHeight.constant = (image.size.height / image.size.width) * self.coverWidth.constant;

    [self.coverImage layoutIfNeeded];
    
}

#pragma mark - Getters

- (NSURLCache *)cache {
    
    return NSURLCache.sharedURLCache;
    
}

@end
