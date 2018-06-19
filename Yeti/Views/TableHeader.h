//
//  TableHeader.h
//  Yeti
//
//  Created by Nikhil Nigade on 19/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/DZKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TableHeader : NibView

@property (weak, nonatomic) IBOutlet UILabel *label;

/**
 The imageView is hidden by default.
 */
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
