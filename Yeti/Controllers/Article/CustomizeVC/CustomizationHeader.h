//
//  CustomizationHeader.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/02/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustomizationHeader : NibView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

NS_ASSUME_NONNULL_END
