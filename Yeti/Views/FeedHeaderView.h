//
//  FeedHeaderView.h
//  Elytra
//
//  Created by Nikhil Nigade on 09/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <DZKit/NibView.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedHeaderView : NibView

@property (weak, nonatomic) IBOutlet UIStackView *mainStackView;
@property (weak, nonatomic) IBOutlet UIStackView *titleStackView;

@property (weak, nonatomic) IBOutlet UIImageView *faviconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *notificationsButton;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;

@end

NS_ASSUME_NONNULL_END
