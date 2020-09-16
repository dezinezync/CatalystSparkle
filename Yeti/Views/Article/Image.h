//
//  Image.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Content.h"
#import "YetiTheme.h"

#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface SizedImage : UIImageView

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, assign) BOOL settingCached;

@property (nonatomic, assign) BOOL cacheImage;
@property (nonatomic, copy) NSString *cachedSuffix;

- (void)updateAspectRatioWithImage:(UIImage *)image;

- (void)sd_cancelCurrentImageLoad;

- (NSURL *)sd_imageURL;

@end

@interface SizedAnimatedImage : SDAnimatedImageView

- (void)updateAspectRatioWithImage:(UIImage *)image;

@end

@interface Image : UIView

@property (nonatomic, assign) NSInteger idx;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSURL *darkModeURL;
@property (nonatomic, copy) NSURL *link;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, strong) NSLayoutConstraint *aspectRatio, *leading, *trailing;

@property (nonatomic, weak, readonly) SizedImage *imageView;

@property (nonatomic, weak) Content *content;

- (void)setImageWithURL:(id)url;

- (void)cancelImageLoading;

@property (nonatomic, assign, getter=isAnimatable, readonly) BOOL animatable;
@property (nonatomic, assign, getter=isAnimating, readonly) BOOL animating;

- (void)setupAnimationControls;

@property (nonatomic, weak) UIButton *startStopButton;

- (void)didTapStartStop:(UIButton *)sender;

@end
