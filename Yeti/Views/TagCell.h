//
//  TagCell.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kTagCell;

@interface TagCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *tagLabel;

@end

NS_ASSUME_NONNULL_END
