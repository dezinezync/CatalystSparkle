//
//  VideoInfo.h
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoInfo : NSObject

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *coverImage;

- (NSDictionary *)dictionaryRepresentation;

@end

NS_ASSUME_NONNULL_END
