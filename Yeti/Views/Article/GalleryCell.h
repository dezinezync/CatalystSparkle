//
//  GalleryCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 30/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kGalleryCell;

@interface GalleryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) NSURLSessionTask *downloadTask;

@end
