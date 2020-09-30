//
//  YTPlayer.h
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <AVKit/AVKit.h>

#if TARGET_OS_MACCATALYST

#import "UISlider+MacCatalyst.h"

#endif

NS_ASSUME_NONNULL_BEGIN

@interface YTPlayer : AVPlayer

@property (nonatomic, weak) AVPlayerViewController *playerViewController;

@end

NS_ASSUME_NONNULL_END
