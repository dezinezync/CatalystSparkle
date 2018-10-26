//
//  DetailAuthorHeaderView.h
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthorHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kDetailAuthorHeaderView;

@interface DetailAuthorHeaderView : UICollectionReusableView

@property (nonatomic, weak) AuthorHeaderView *headerContent;

- (void)setupAppearance;

@end

NS_ASSUME_NONNULL_END
