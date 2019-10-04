//
//  ImageViewerController.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN API_AVAILABLE(ios(13.0))
@interface ImageViewerController : UICollectionViewController

+ (UINavigationController *)instanceWithImages:(NSPointerArray * _Nonnull)images;

@end

NS_ASSUME_NONNULL_END
