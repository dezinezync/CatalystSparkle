//
//  Image.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SizedImage : UIImageView

@end

@interface Image : UIView

@property (nonatomic, assign) NSInteger idx;
@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, strong) NSLayoutConstraint *aspectRatio, *leading, *trailing;

@property (nonatomic, weak, readonly) UIImageView *imageView;

- (void)updateAspectRatioWithImage:(UIImage *)image;

- (void)il_setImageWithURL:(id)url;

@end
