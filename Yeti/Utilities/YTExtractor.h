//
//  YTExtractor.h
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSString+Components.h"
#import "VideoInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTExtractor : NSObject

- (void)extract:(NSString *)videoID
        success:(void (^)(VideoInfo * videoInfo))successCB
          error:(void (^)(NSError * error))errorCB;

@end

NS_ASSUME_NONNULL_END
