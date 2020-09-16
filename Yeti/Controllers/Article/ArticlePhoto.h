//
//  ArticlePhoto.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <NYTPhotoViewer/NYTPhoto.h>

NS_ASSUME_NONNULL_BEGIN

@class SDWebImageCombinedOperation;

@interface ArticlePhoto : NSObject /* <NYTPhoto> */

@property (nonatomic, copy) UIImage *downloadedImage;

// Redeclare all the properties as readwrite for sample/testing purposes.
@property (nonatomic) UIImage *image;
@property (nonatomic) NSData *imageData;
@property (nonatomic) UIImage *placeholderImage;

@property (nonatomic) NSAttributedString *attributedCaptionTitle;
@property (nonatomic) NSAttributedString *attributedCaptionSummary;
@property (nonatomic) NSAttributedString *attributedCaptionCredit;

@property (nonatomic, copy) NSURL * _Nonnull URL;
@property (nonatomic, weak) UIView * _Nullable referenceView;
@property (nonatomic) SDWebImageCombinedOperation * _Nullable task;

@end

NS_ASSUME_NONNULL_END
