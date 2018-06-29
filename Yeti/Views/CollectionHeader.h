//
//  CollectionHeader.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const kCollectionHeader;

@interface CollectionHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UILabel *label;

/**
 The imageView is hidden by default.
 */
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
