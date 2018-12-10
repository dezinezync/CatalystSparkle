//
//  YTPlayer.h
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTPlayer : AVPlayer

@property (nonatomic, weak) AVPlayerViewController *playerViewController;

@end

NS_ASSUME_NONNULL_END
