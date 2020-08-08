//
//  PhotosController.m
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "PhotosController.h"
/*
#import <NYTPhotoViewerCore/NYTPhotoViewerCore.h>

#import <SDWebImage/SDWebImageManager.h>

#import "ArticlePhoto.h"

@interface PhotosController () <NYTPhotosViewControllerDelegate, NYTPhotoViewerDataSource>

@property (nonatomic, copy) NSDictionary *userInfo;

@property (nonatomic, strong) NYTPhotosViewController *photosVC;

@property (nonatomic, strong) ArticlePhoto *photo;

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
    // Do any additional setup after loading the view.
    
    NYTPhotosViewController *photosVC = [[NYTPhotosViewController alloc] initWithDataSource:self initialPhoto:self.photo delegate:self];
    
    photosVC.leftBarButtonItem = nil;
    
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

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self photosViewController:self.photosVC didNavigateToPhoto:self.photo atIndex:0];
    
}

#pragma mark - Getter

- (ArticlePhoto *)photo {
    
    if (_photo == nil) {
        
        ArticlePhoto *photo = [ArticlePhoto new];
        
        if (self.userInfo[@"image"]) {
            
            photo.image = [UIImage imageWithData:self.userInfo[@"image"]];
            photo.imageData = self.userInfo[@"image"];
            
        }
        
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark && self.userInfo[@"darkURL"] != nil) {
            
            photo.URL = self.userInfo[@"darkURL"];
            
        }
        else if (self.userInfo[@"URL"] != nil) {
            
            photo.URL = self.userInfo[@"URL"];
            
        }
        
        if (self.userInfo[@"alt"]) {
            
            photo.attributedCaptionTitle = [[NSAttributedString alloc] initWithString:[self.userInfo valueForKey:@"alt"] attributes:@{
                NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCallout],
                NSForegroundColorAttributeName: UIColor.whiteColor
            }];
            
        }
        
        _photo = photo;
        
    }
    
    return _photo;
    
}

#pragma mark - Datasource

- (NSNumber *)numberOfPhotos {
    
    return @1;
    
}

- (NSInteger)indexOfPhoto:(id<NYTPhoto>)photo {
    
    return 0;
    
}

- (id<NYTPhoto>)photoAtIndex:(NSInteger)photoIndex {
    
    return self.photo;
    
}

#pragma mark - Delegate

- (void)photosViewController:(NYTPhotosViewController *)photosViewController didNavigateToPhoto:(id<NYTPhoto>)photo atIndex:(NSUInteger)photoIndex {
    
    if (self.photo.downloadedImage != nil) {
        return;
    }
    
    if (self.photo.task != nil) {
        return;
    }
    
    NSURL *URL = self.photo.URL;
    
    self.photo.task = [[SDWebImageManager sharedManager] loadImageWithURL:URL options:SDWebImageScaleDownLargeImages progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
       
        if (image != nil) {
            
            self.photo.downloadedImage = image;
            self.photo.imageData = data ?: self.photo.imageData;
            
            CGRect frame = self.view.window.frame;
            CGSize maxSize = UIScreen.mainScreen.currentMode.size;
            
            if (image.size.width < maxSize.width) {
                
                CGFloat maxHeight = 0.f;
                
                if (image.size.height > maxSize.height) {
                    
                    maxHeight = image.size.height * maxSize.height / maxSize.width;
                    
                }
                else {
                    
                    maxHeight = image.size.height;
                    
                }
                
                CGRect newRect = CGRectMake(frame.origin.x, frame.origin.y, image.size.width + 24.f, maxHeight + 24.f);
                
                self.view.window.windowScene.sizeRestrictions.minimumSize = newRect.size;
                
            }
            
            [self.photosVC reloadPhotosAnimated:YES];
            
        }
        
    }];
    
}

@end
*/
