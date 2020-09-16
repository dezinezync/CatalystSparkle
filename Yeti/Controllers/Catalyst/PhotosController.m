//
//  PhotosController.m
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "PhotosController.h"

#import "IDMPhotoBrowser.h"

#import <SDWebImage/SDWebImageManager.h>

#import "ArticlePhoto.h"

@interface PhotosController ()

@property (nonatomic, copy) NSDictionary *userInfo;

@property (nonatomic, strong) IDMPhotoBrowser *photosVC;

@property (nonatomic, strong) IDMPhoto *photo;

@end

@implementation PhotosController

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    
    if (self = [super init]) {
        
        self.userInfo = userInfo;
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    IDMPhotoBrowser *photosVC = [[IDMPhotoBrowser alloc] initWithPhotos:@[self.photo]];
    photosVC.usePopAnimation = YES;
    
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17.f weight:UIImageSymbolWeightMedium];
    
    UIImage *shareImage = [UIImage systemImageNamed:@"square.and.arrow.up" withConfiguration:config];
    
    UIColor *fadedColor = [UIColor colorWithWhite:1.f alpha:0.3f];
    
    photosVC.actionButtonImage = [shareImage imageWithTintColor:fadedColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    photosVC.actionButtonSelectedImage = [shareImage imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    
    self.photosVC = photosVC;
    
    [self addChildViewController:self.photosVC];
    
    [self.view addSubview:self.photosVC.view];
    
    self.photosVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.photosVC.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.photosVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.photosVC.view.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.photosVC.view.heightAnchor constraintEqualToAnchor:self.view.heightAnchor].active = YES;
    
    [self.photosVC didMoveToParentViewController:self];
    
}

#pragma mark - Getter

- (IDMPhoto *)photo {
    
    if (_photo == nil) {
        
        IDMPhoto *photo = [IDMPhoto new];
        
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark && self.userInfo[@"darkURL"] != nil) {
            
            photo.photoURL = self.userInfo[@"darkURL"];
            
        }
        else if (self.userInfo[@"URL"] != nil) {
            
            photo.photoURL = self.userInfo[@"URL"];
            
        }
        
        if (self.userInfo[@"alt"]) {
            
            photo.caption = [self.userInfo valueForKey:@"alt"];
            
        }
        
        _photo = photo;
        
    }
    
    return _photo;
    
}

@end
