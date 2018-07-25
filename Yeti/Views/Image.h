//
//  Image.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImageView.h>

@interface SizedImage : UIImageView

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, assign) BOOL settingCached;

- (void)updateAspectRatioWithImage:(UIImage *)image;

@end

@interface SizedAnimatedImage : FLAnimatedImageView

- (void)updateAspectRatioWithImage:(UIImage *)image;

@end

@interface Image : UIView

@property (nonatomic, assign) NSInteger idx;
@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, strong) NSLayoutConstraint *aspectRatio, *leading, *trailing;

@property (nonatomic, weak, readonly) SizedImage *imageView;

- (void)il_setImageWithURL:(id)url;

@property (nonatomic, assign, getter=isAnimatable, readonly) BOOL animatable;
@property (nonatomic, assign, getter=isAnimating, readonly) BOOL animating;

- (void)setupAnimationControls;

@property (nonatomic, weak) UIButton *startStopButton;

- (void)didTapStartStop:(UIButton *)sender;

@end
