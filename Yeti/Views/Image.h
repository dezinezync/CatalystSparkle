//
//  Image.h
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Image : UIImageView

@property (nonatomic, assign) NSInteger idx;
@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, strong) NSLayoutConstraint *aspectRatio, *leading, *trailing;

- (void)updateAspectRatioWithImage:(UIImage *)image;

@end
