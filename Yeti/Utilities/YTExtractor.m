//
//  YTExtractor.m
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YTExtractor.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

NSString * const ERROR_cantExtractVideoId = @"Couldn't extract video id from the url";
NSString * const ERROR_cantConstructRequestUrl = @"Couldn't construct URL for youtube info request";
NSString * const ERROR_noDataInResponse = @"No data in youtube info response";
NSString * const ERROR_cantConvertDataToString = @"Couldn't convert response data to string";
NSString * const ERROR_cantExtractFmtStreamMap = @"Couldn't extract url_encoded_fmt_stream_map from youtube response";
NSString * const ERROR_unknown = @"Unknown error occured";

#define infoBasePrefix @"https://www.youtube.com/get_video_info?video_id=%@"
#define userAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"

@implementation YTExtractor

- (void)extract:(NSString *)videoID success:(void (^)(VideoInfo * _Nonnull))successCB error:(void (^)(NSError * _Nonnull))errorCB {
    
    if (!videoID || [videoID isBlank]) {
        if (errorCB != nil) {
            
            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: ERROR_cantExtractVideoId}];
            
            errorCB(error);
        }
        
        return;
    }
    
    if ([videoID containsString:@"?"]) {
        NSRange range = [videoID rangeOfString:@"?"];
        if (range.location != NSNotFound) {
            videoID = [videoID substringToIndex:range.location];
        }
    }
    
    [self extractRawInfo:videoID success:^(VideoInfo * _Nonnull videoInfo) {
        
        if (successCB) {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(videoInfo);
            });
            
        }
        
    } error:^(NSError * _Nonnull error) {
        
        if (errorCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorCB(error);
            });
            
        }
        
    }];
    
}

- (void)extractRawInfo:(NSString *)videoID success:(void (^)(VideoInfo * _Nonnull))successCB error:(void (^)(NSError * _Nonnull))errorCB {
    
    NSURL *baseURL = formattedURL(infoBasePrefix, videoID);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:baseURL];
    request.HTTPMethod = @"GET";
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSString *dataString;
        
        if (data == nil || [data length] == 0) {
            error = [NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: ERROR_noDataInResponse}];
        }
        else {
            dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            if (dataString == nil) {
                error = [NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: ERROR_cantConvertDataToString}];
            }
        }
        
        if (error != nil) {
            if (errorCB != nil) {
                errorCB(error);
            }
            
            return;
        }
        
        NSArray *mapped = [self extractInfoFromDataString:dataString];
        
        if (mapped && [mapped isKindOfClass:NSError.class]) {
            if (errorCB) {
                errorCB((NSError *)mapped);
            }
            
            return;
        }
        
        NSString *thumbnail = [mapped firstObject];
        
        NSArray <NSDictionary *> *rawDict = [mapped lastObject];
        
        VideoInfo *videoInfo = [[VideoInfo alloc] init];
        videoInfo.coverImage = thumbnail;
        
        NSString *URI = nil;
        
        for (NSDictionary *dict in rawDict) {
            
            NSString *type = dict[@"type"];
            
            if (type && [type containsString:@"video/mp4"] == YES) {
                
                NSString *size = dict[@"quality"];
                
                if([size containsString:@"720"] == YES) {
                    URI = dict[@"url"];
                }
                
            }
        }
        
        NSURL *URL = nil;
        
        if (URI) {
            URL = [NSURL URLWithString:URI];
        }
        
        videoInfo.url = URL;
        
        successCB(videoInfo);
        
    }];
    
    [task resume];
    
}

- (id)extractInfoFromDataString:(NSString *)dataString {
    
    NSDictionary *pairs = [dataString queryComponents];
    
    NSString *thumbnail = pairs[@"thumbnail_url"];
    
    if ([[thumbnail lastPathComponent] isEqualToString:@"default.jpg"]) {
        thumbnail = [thumbnail stringByReplacingOccurrencesOfString:@"/default.jpg" withString:@"/maxresdefault.jpg"];
    }
    
    NSString * streamsMap = pairs[@"url_encoded_fmt_stream_map"];
    
    if (!streamsMap) {
        NSString *errorString = pairs[@"reason"];
        NSString *errorCodeString = pairs[@"errorcode"];
        
        return [NSError errorWithDomain:NSCocoaErrorDomain code:errorCodeString.integerValue userInfo:@{NSLocalizedDescriptionKey: (errorString ?: ERROR_cantExtractFmtStreamMap)}];
    }
    
    NSArray <NSString *> *streamMapComponents = [streamsMap componentsSeparatedByString:@","];
    
    NSArray <NSDictionary *> *mappedInfo = [streamMapComponents rz_map:^id(NSString *obj, NSUInteger idx, NSArray *array) {
       
        return [obj queryComponents];
        
    }];
    
    return @[thumbnail, mappedInfo];
    
}

@end
