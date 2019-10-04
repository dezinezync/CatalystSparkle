//
//  ImageViewerCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kImageViewerCell;

UIKIT_EXTERN API_AVAILABLE(ios(13.0))
@interface ImageViewerCell : UICollectionViewCell

+ (void)registerOn:(UICollectionView *)collectionView;

@property (nonatomic, weak) UICollectionViewController *viewController;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)setImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
