//
//  Youtube.h
//  Yeti
//
//  Created by Nikhil Nigade on 17/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Youtube : UIView

// passing only the frame will setup the view to always be 16:9
- (instancetype)initWithFrame:(CGRect)frame;

// set either or...
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSString *videoID;

@end
