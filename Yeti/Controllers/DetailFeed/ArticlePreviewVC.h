//
//  ArticlePreviewVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArticlePreviewVC : UIViewController

+ (instancetype)instanceForFeed:(FeedItem *)item;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *captionLabel;

@end

NS_ASSUME_NONNULL_END
